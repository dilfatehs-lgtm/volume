import SwiftData
import XCTest
@testable import Volume

/// Logging a workout you forgot to log at the time.
///
/// The governing rule: **goals are commitments, workouts are facts.** Goal changes stay
/// forward-only so nobody can move the goalposts, but correcting what actually happened
/// must count — even when that makes a streak longer, and even when it makes one shorter.
@MainActor
final class BackdatingTests: VolumeTestCase {

    private func previous(for session: WorkoutSession) -> WorkoutSession? {
        SessionHistory.previousSession(for: session, among: allSessions())
    }

    /// A workout dropped into a gap becomes the target for everything after it, and takes
    /// its own target from what came before.
    func testBackdatedSessionSlotsIntoTheComparisonChain() {
        let push = makeTemplate("Push")
        let first = makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        let latest = makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1200)

        XCTAssertEqual(previous(for: latest)?.persistentModelID, first.persistentModelID)

        // The forgotten Wednesday session, logged days later.
        let backdated = makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)

        XCTAssertEqual(previous(for: backdated)?.persistentModelID, first.persistentModelID)
        XCTAssertEqual(previous(for: latest)?.persistentModelID, backdated.persistentModelID,
                       "The later session should now be measured against the backdated one")
    }

    func testBackdatingCanExtendTheRecordStreak() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1200)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1)

        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2,
                       "1000 → 1100 → 1200 is two records in a row")
    }

    /// The uncomfortable half of the same rule. Slotting in a strong forgotten session can
    /// mean the latest workout no longer beats what precedes it. That's the truth, and the
    /// number should be true rather than flattering.
    func testBackdatingCanBreakTheRecordStreak() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1200)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1)

        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1300)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 0,
                       "1200 no longer beats the 1300 that now precedes it")
    }

    /// Filling in a week you actually trained should repair the week streak — this is a
    /// correction of fact, not a moved goalpost.
    func testBackdatingRetroactivelyCompletesAWeek() {
        let push = makeTemplate("Push")
        let goal = WeeklyGoal(daysPerWeek: 3, effectiveFrom: .distantPast)
        context.insert(goal)

        // Week of Jun 28: complete. Week of Jul 5: only one day logged. Week of Jul 12:
        // complete. Current week (Jul 19): one day so far.
        for offset in 0..<3 { makeSession(push, on: VolumeTestCase.date(2026, 6, 28 + offset), score: 100) }
        makeSession(push, on: VolumeTestCase.date(2026, 7, 6), score: 100)
        for offset in 0..<3 { makeSession(push, on: VolumeTestCase.date(2026, 7, 12 + offset), score: 100) }
        makeSession(push, on: VolumeTestCase.date(2026, 7, 20), score: 100)

        XCTAssertEqual(StreakCalculator.weeklyStreak(sessions: allSessions(), goals: [goal],
                                                     calendar: calendar, now: now), 1,
                       "The incomplete Jul 5 week stops the walk back")

        // Log the two sessions from that week that never got recorded.
        makeSession(push, on: VolumeTestCase.date(2026, 7, 7), score: 100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 9), score: 100)

        XCTAssertEqual(StreakCalculator.weeklyStreak(sessions: allSessions(), goals: [goal],
                                                     calendar: calendar, now: now), 3,
                       "With Jul 5 repaired, the streak reaches back through Jun 28")
    }

    func testAFutureDateIsClampedToNow() {
        let push = makeTemplate("Push")
        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)

        let farFuture = VolumeTestCase.date(2030, 1, 1)
        model.updateDate(farFuture)

        XCTAssertLessThanOrEqual(session.date, Date(),
                                 "A workout in the future would scramble comparison ordering")
    }

    func testMovingAWorkoutUpdatesWhatItIsComparedAgainst() {
        let push = makeTemplate("Push")
        let june = makeSession(push, on: VolumeTestCase.date(2026, 6, 10), score: 900)
        let july = makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        let misfiled = makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 950)

        XCTAssertEqual(previous(for: misfiled)?.persistentModelID, july.persistentModelID)

        // It actually happened in June, before the 1,000.
        let model = ActiveWorkoutModel(session: misfiled, context: context,
                                       unit: .pounds, mode: .editingPast)
        model.updateDate(VolumeTestCase.date(2026, 6, 20))

        XCTAssertEqual(previous(for: misfiled)?.persistentModelID, june.persistentModelID,
                       "Moving a workout re-points it at whatever now precedes it")
    }
}

final class WorkoutDateLabelTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    func testLabelsReadNaturally() {
        let now = Date()
        XCTAssertTrue(WorkoutDateLabel.text(for: now, now: now, calendar: calendar).hasPrefix("Now · "))

        let earlierToday = calendar.date(byAdding: .hour, value: -6, to: now)!
        if calendar.isDateInToday(earlierToday) {
            XCTAssertTrue(WorkoutDateLabel.text(for: earlierToday, now: now, calendar: calendar)
                .hasPrefix("Today · "))
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(WorkoutDateLabel.text(for: yesterday, now: now, calendar: calendar)
            .hasPrefix("Yesterday · "))
    }

    func testOnlyTodayCountsAsNotBackdated() {
        let now = Date()
        XCTAssertFalse(WorkoutDateLabel.isBackdated(now, now: now, calendar: calendar))
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now)!
        XCTAssertTrue(WorkoutDateLabel.isBackdated(lastWeek, now: now, calendar: calendar))
    }
}

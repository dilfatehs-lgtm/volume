import SwiftData
import XCTest
@testable import Volume

@MainActor
final class BestStreakTests: VolumeTestCase {

    func testBestRecordStreakRemembersARunThatHasSinceBeenBroken() {
        let push = makeTemplate("Push")
        // 1000 → 1100 → 1200 → 1300 (three records), then a miss, then one more record.
        for (index, score) in [1000, 1100, 1200, 1300, 1250, 1400].enumerated() {
            makeSession(push, on: VolumeTestCase.date(2026, 7, 1 + index), score: score)
        }

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1)
        XCTAssertEqual(StreakCalculator.bestRecordStreak(sessions: allSessions(), unit: .pounds), 3)
    }

    func testCurrentAndBestAgreeWhenTheBestRunIsTheCurrentOne() {
        let push = makeTemplate("Push")
        for (index, score) in [1000, 1100, 1200].enumerated() {
            makeSession(push, on: VolumeTestCase.date(2026, 7, 1 + index), score: score)
        }
        let sessions = allSessions()
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: sessions, unit: .pounds), 2)
        XCTAssertEqual(StreakCalculator.bestRecordStreak(sessions: sessions, unit: .pounds), 2)
    }

    /// A brand-new workout tried partway through a run is neutral, so it must not chop the
    /// best streak in half — the same rule the current streak uses.
    func testANewWorkoutMidRunDoesNotSplitTheBestStreak() {
        let push = makeTemplate("Push")
        let yoga = makeTemplate("Yoga")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 2), score: 1100)
        makeSession(yoga, on: VolumeTestCase.date(2026, 7, 3), score: 50)     // neutral
        makeSession(push, on: VolumeTestCase.date(2026, 7, 4), score: 1200)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 900)    // breaks it

        XCTAssertEqual(StreakCalculator.bestRecordStreak(sessions: allSessions(), unit: .pounds), 2)
    }

    func testBestWeeklyStreakSurvivesALaterMiss() {
        let push = makeTemplate("Push")
        let goal = WeeklyGoal(daysPerWeek: 3, effectiveFrom: .distantPast)
        context.insert(goal)

        // Jun 14, Jun 21, Jun 28 complete; Jul 5 missed; Jul 12 complete; current partial.
        for start in [(6, 14), (6, 21), (6, 28), (7, 12)] {
            for offset in 0..<3 {
                makeSession(push, on: VolumeTestCase.date(2026, start.0, start.1 + offset), score: 100)
            }
        }
        makeSession(push, on: VolumeTestCase.date(2026, 7, 6), score: 100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 20), score: 100)

        let sessions = allSessions()
        XCTAssertEqual(StreakCalculator.weeklyStreak(sessions: sessions, goals: [goal],
                                                     calendar: calendar, now: now), 1)
        XCTAssertEqual(StreakCalculator.bestWeeklyStreak(sessions: sessions, goals: [goal],
                                                         calendar: calendar, now: now), 3)
    }

    /// A week with no workouts at all is a miss, not a gap to be skipped over.
    func testAnEmptyWeekBreaksTheBestWeeklyStreak() {
        let push = makeTemplate("Push")
        let goal = WeeklyGoal(daysPerWeek: 3, effectiveFrom: .distantPast)
        context.insert(goal)

        for start in [(6, 14), (6, 28)] {
            for offset in 0..<3 {
                makeSession(push, on: VolumeTestCase.date(2026, start.0, start.1 + offset), score: 100)
            }
        }
        // Nothing at all in the week of Jun 21.

        XCTAssertEqual(StreakCalculator.bestWeeklyStreak(sessions: allSessions(), goals: [goal],
                                                         calendar: calendar, now: now), 1)
    }
}

@MainActor
final class WorkoutRecordsTests: VolumeTestCase {

    func testBestScoreIsTheMaximumNotTheLatest() throws {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1500)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1200)

        let record = try XCTUnwrap(WorkoutRecords.all(sessions: allSessions(), unit: .pounds).first)
        XCTAssertEqual(record.bestScore, 1500)
        XCTAssertEqual(record.lastScore, 1200)
        XCTAssertEqual(record.sessionCount, 3)
        XCTAssertFalse(record.isAtBest)
        XCTAssertEqual(record.bestDate, VolumeTestCase.date(2026, 7, 8))
    }

    func testPersonalRecordCountMatchesTheSessionsThatBeatTheirTarget() {
        let push = makeTemplate("Push")
        // neutral, beat, beat, miss, beat  →  3 PRs
        for (index, score) in [1000, 1100, 1200, 1150, 1300].enumerated() {
            makeSession(push, on: VolumeTestCase.date(2026, 7, 1 + index), score: score)
        }

        let records = WorkoutRecords.all(sessions: allSessions(), unit: .pounds)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].personalRecords, 3)
    }

    func testEachWorkoutIsTrackedSeparatelyAndOrderedByRecency() {
        let push = makeTemplate("Push")
        let legs = makeTemplate("Legs")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(legs, on: VolumeTestCase.date(2026, 7, 2), score: 5000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 10), score: 1100)

        let records = WorkoutRecords.all(sessions: allSessions(), unit: .pounds)
        XCTAssertEqual(records.map(\.name), ["Push", "Legs"], "Most recently performed first")
        XCTAssertEqual(records.first(where: { $0.name == "Legs" })?.bestScore, 5000)
        XCTAssertEqual(records.first(where: { $0.name == "Push" })?.personalRecords, 1)
    }

    /// A deleted template leaves its sessions behind; those records still belong together.
    func testOrphanedSessionsStillGroupIntoOneRecord() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)
        try? context.save()

        context.delete(push)
        try? context.save()

        let records = WorkoutRecords.all(sessions: allSessions(), unit: .pounds)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].name, "Push")
        XCTAssertEqual(records[0].sessionCount, 2)
        XCTAssertNil(records[0].template)
    }

    func testIncompleteSessionsAreExcluded() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 8),
                    sets: [(reps: 9999, weight: nil)], completed: false)

        let records = WorkoutRecords.all(sessions: allSessions(), unit: .pounds)
        XCTAssertEqual(records[0].sessionCount, 1)
        XCTAssertEqual(records[0].bestScore, 1000, "A workout in progress isn't a record yet")
    }
}

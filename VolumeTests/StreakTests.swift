import SwiftData
import XCTest
@testable import Volume

@MainActor
final class RecordStreakTests: VolumeTestCase {

    func testConsecutiveBeatsIncrementTheStreak() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 1100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 9), score: 1200)

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2)
    }

    func testFallingShortResetsTheStreak() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 1100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 9), score: 1050)

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 0)
    }

    func testMatchingTheExactScoreDoesNotCountAsBeatingIt() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 1000)

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 0)
    }

    /// The rule agreed for a brand-new workout: neutral. It neither inflates the streak
    /// nor punishes the user for trying something new.
    func testFirstSessionOfANewTemplateIsNeutral() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 1100)   // streak = 1

        let brandNew = makeTemplate("Yoga")
        makeSession(brandNew, on: VolumeTestCase.date(2026, 7, 6), score: 50)

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1,
                       "A first-ever session must not reset the streak…")

        makeSession(push, on: VolumeTestCase.date(2026, 7, 9), score: 1200)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2,
                       "…nor should it have added to it")
    }

    func testInterleavedTemplatesAreJudgedAgainstThemselves() {
        let push = makeTemplate("Push")
        let legs = makeTemplate("Legs")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(legs, on: VolumeTestCase.date(2026, 7, 2), score: 5000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 4), score: 1100)   // beats Push
        makeSession(legs, on: VolumeTestCase.date(2026, 7, 5), score: 5100)   // beats Legs

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2)
    }

    func testInProgressSessionIsNotCounted() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 5), score: 1100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 9),
                    sets: [(reps: 1, weight: nil)], completed: false)

        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1,
                       "A workout still in progress must not break the streak")
    }
}

@MainActor
final class WeeklyGoalStreakTests: VolumeTestCase {

    private func goal(_ days: Int, from date: Date) -> WeeklyGoal {
        let goal = WeeklyGoal(daysPerWeek: days,
                              effectiveFrom: StreakCalculator.weekStart(for: date, calendar: calendar))
        context.insert(goal)
        return goal
    }

    private func streak(_ goals: [WeeklyGoal]) -> Int {
        StreakCalculator.weeklyStreak(sessions: allSessions(), goals: goals,
                                      calendar: calendar, now: now)
    }

    /// Two workouts on one day is one day toward the goal. Otherwise cramming games it.
    func testDistinctDaysCountNotSessions() {
        let push = makeTemplate("Push")
        let day = VolumeTestCase.date(2026, 7, 20, hour: 8)
        makeSession(push, on: day, score: 100)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 20, hour: 19), score: 100)

        let goals = [goal(3, from: .distantPast)]
        let progress = StreakCalculator.currentWeekProgress(sessions: allSessions(), goals: goals,
                                                            calendar: calendar, now: now)
        XCTAssertEqual(progress.daysCompleted, 1)
        XCTAssertFalse(progress.isMet)
    }

    /// The bug that would otherwise show every user a broken streak each Monday morning.
    func testPartiallyCompleteCurrentWeekDoesNotBreakTheStreak() {
        let push = makeTemplate("Push")
        // Three full weeks before this one: Sun 28 Jun, 5 Jul, 12 Jul.
        for weekStartDay in [28, 5, 12] {
            let month = weekStartDay == 28 ? 6 : 7
            for offset in 0..<3 {
                makeSession(push, on: VolumeTestCase.date(2026, month, weekStartDay + offset), score: 100)
            }
        }
        // Current week (starts Sun 19 Jul): only one day so far.
        makeSession(push, on: VolumeTestCase.date(2026, 7, 20), score: 100)

        let goals = [goal(3, from: .distantPast)]
        let progress = StreakCalculator.currentWeekProgress(sessions: allSessions(), goals: goals,
                                                            calendar: calendar, now: now)
        XCTAssertEqual(progress.daysCompleted, 1)
        XCTAssertEqual(progress.goal, 3)
        XCTAssertEqual(streak(goals), 3, "The in-progress week should be skipped, not counted as a failure")
    }

    func testCurrentWeekCountsAsSoonAsTheGoalIsMet() {
        let push = makeTemplate("Push")
        for offset in 0..<3 {
            makeSession(push, on: VolumeTestCase.date(2026, 7, 12 + offset), score: 100)
        }
        for offset in 0..<3 {
            makeSession(push, on: VolumeTestCase.date(2026, 7, 19 + offset), score: 100)
        }

        let goals = [goal(3, from: .distantPast)]
        XCTAssertEqual(streak(goals), 2)
    }

    func testMissedWeekBreaksTheStreak() {
        let push = makeTemplate("Push")
        for offset in 0..<3 { makeSession(push, on: VolumeTestCase.date(2026, 7, 5 + offset), score: 100) }
        // Week of 12 Jul: only one day — a miss.
        makeSession(push, on: VolumeTestCase.date(2026, 7, 13), score: 100)
        for offset in 0..<3 { makeSession(push, on: VolumeTestCase.date(2026, 7, 19 + offset), score: 100) }

        let goals = [goal(3, from: .distantPast)]
        XCTAssertEqual(streak(goals), 1, "Only the current week survives; the miss stops the walk back")
    }

    /// Forward-only goals: past weeks keep being judged by the goal that applied then.
    func testRaisingTheGoalDoesNotWipeAnEarnedStreak() {
        let push = makeTemplate("Push")
        // Two prior weeks with 2 days each, under a goal of 2.
        for start in [5, 12] {
            for offset in 0..<2 {
                makeSession(push, on: VolumeTestCase.date(2026, 7, start + offset), score: 100)
            }
        }
        // This week the user raises the goal to 5 and has done 2 days.
        for offset in 0..<2 { makeSession(push, on: VolumeTestCase.date(2026, 7, 19 + offset), score: 100) }

        let goals = [goal(2, from: .distantPast), goal(5, from: now)]

        XCTAssertEqual(StreakCalculator.currentGoal(goals: goals, calendar: calendar, now: now), 5)
        XCTAssertEqual(streak(goals), 2,
                       "Weeks completed under the old goal of 2 must still count")
    }

    func testLoweringTheGoalCannotManufactureAStreak() {
        let push = makeTemplate("Push")
        // Three prior weeks with only 1 day each, under a goal of 4 — all failures.
        for start in [28, 5, 12] {
            let month = start == 28 ? 6 : 7
            makeSession(push, on: VolumeTestCase.date(2026, month, start), score: 100)
        }
        // User drops the goal to 1 this week and trains once.
        makeSession(push, on: VolumeTestCase.date(2026, 7, 20), score: 100)

        let goals = [goal(4, from: .distantPast), goal(1, from: now)]

        XCTAssertEqual(streak(goals), 1,
                       "Only the current week qualifies; the lowered goal must not retroactively rescue past weeks")
    }

    func testSettingTheGoalTwiceInOneWeekUpdatesRatherThanAccumulates() {
        WeeklyGoal.setGoal(4, in: context, calendar: calendar, now: now)
        WeeklyGoal.setGoal(2, in: context, calendar: calendar, now: now)

        let stored = (try? context.fetch(FetchDescriptor<WeeklyGoal>())) ?? []
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.daysPerWeek, 2)
    }

    func testGoalIsClampedToOneThroughSeven() {
        let low = WeeklyGoal.setGoal(0, in: context, calendar: calendar, now: now)
        XCTAssertEqual(low.daysPerWeek, 1)
        let high = WeeklyGoal.setGoal(99, in: context, calendar: calendar, now: now)
        XCTAssertEqual(high.daysPerWeek, 7)
    }

    func testNoWorkoutsMeansNoStreak() {
        XCTAssertEqual(streak([goal(3, from: .distantPast)]), 0)
    }
}

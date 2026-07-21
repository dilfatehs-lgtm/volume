import XCTest
@testable import Volume

/// The "no split picker needed" guarantee: comparisons are always like-for-like, keyed
/// on the template the user named.
@MainActor
final class ComparisonTests: VolumeTestCase {

    /// Push → Legs → Push. The second Push must be measured against the *first Push*,
    /// not against the Legs session that happened in between.
    func testScoreToBeatIgnoresOtherWorkoutsInBetween() {
        let push = makeTemplate("Push")
        let legs = makeTemplate("Legs")

        let firstPush = makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(legs, on: VolumeTestCase.date(2026, 7, 3), score: 9999)
        let secondPush = makeSession(push, on: VolumeTestCase.date(2026, 7, 6), score: 1100)

        let previous = SessionHistory.previousSession(for: secondPush, among: allSessions())
        XCTAssertEqual(previous?.persistentModelID, firstPush.persistentModelID)
        XCTAssertEqual(SessionHistory.didBeatTarget(secondPush, among: allSessions(), unit: .pounds),
                       true)
    }

    func testFirstSessionOfATemplateHasNothingToBeat() {
        let push = makeTemplate("Push")
        let first = makeSession(push, on: now, score: 1000)

        XCTAssertNil(SessionHistory.previousSession(for: first, among: allSessions()))
        XCTAssertNil(SessionHistory.didBeatTarget(first, among: allSessions(), unit: .pounds))
    }

    func testIncompleteSessionsAreNeverUsedAsATarget() {
        let push = makeTemplate("Push")
        let completed = makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 4),
                    sets: [(reps: 500, weight: nil)], completed: false)
        let latest = makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)

        XCTAssertEqual(SessionHistory.previousSession(for: latest, among: allSessions())?
                        .persistentModelID,
                       completed.persistentModelID)
    }

    func testLastCompletedSessionForTemplateIsTheMostRecent() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        let latest = makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 900)

        let last = SessionHistory.lastCompletedSession(for: push, among: allSessions())
        // Most recent, not best ever — 900 beats 1000 here on recency.
        XCTAssertEqual(last?.persistentModelID, latest.persistentModelID)
    }

    /// Deleting a template must not destroy the log, and orphaned sessions must still
    /// group together by their snapshotted name.
    func testDeletingATemplateKeepsItsSessionsAndTheirName() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)
        try? context.save()

        context.delete(push)
        try? context.save()

        let survivors = allSessions()
        XCTAssertEqual(survivors.count, 2)
        for session in survivors {
            XCTAssertEqual(session.displayName, "Push")
        }
        XCTAssertEqual(Set(survivors.map(\.comparisonKey)).count, 1,
                       "Orphaned sessions of the same workout must still compare against each other")
    }
}

@MainActor
final class TemplateNameMatcherTests: XCTestCase {

    func testCatchesTheRealFailureCase() {
        // The case that silently resets someone's score history.
        XCTAssertTrue(TemplateNameMatcher.areSimilar("Leg Day", "Legs"))
        XCTAssertTrue(TemplateNameMatcher.areSimilar("Push Day", "Push"))
        XCTAssertTrue(TemplateNameMatcher.areSimilar("Upper", "Upper Body"))
        XCTAssertTrue(TemplateNameMatcher.areSimilar("leg day", "LEG DAY"))
    }

    func testKeepsGenuinelyDifferentWorkoutsApart() {
        XCTAssertFalse(TemplateNameMatcher.areSimilar("Push", "Pull"))
        XCTAssertFalse(TemplateNameMatcher.areSimilar("Leg Day", "Arm Day"))
        XCTAssertFalse(TemplateNameMatcher.areSimilar("Upper", "Lower"))
        XCTAssertFalse(TemplateNameMatcher.areSimilar("Maria's Tuesday Workout", "Push"))
    }

    func testNamesMadeOnlyOfFillerWordsFallBackToExactComparison() {
        // "Workout" reduces to no meaningful tokens; it should only match itself.
        XCTAssertTrue(TemplateNameMatcher.areSimilar("Workout", "workout"))
        XCTAssertFalse(TemplateNameMatcher.areSimilar("Workout", "Push"))
    }
}

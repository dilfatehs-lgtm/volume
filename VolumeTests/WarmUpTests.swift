import SwiftData
import XCTest
@testable import Volume

/// Warm-up sets are part of the log but not part of the work.
///
/// The reason they're excluded: if warm-ups counted, logging them would inflate your score,
/// so you'd either skip recording them or pollute the number you're trying to beat. With
/// them excluded the score means *working* volume, and a day of heavy warm-ups can't beat a
/// day of hard work sets.
@MainActor
final class WarmUpTests: VolumeTestCase {

    func testWarmUpSetsScoreNothing() {
        let session = makeSession(makeTemplate("Push"), on: now,
                                  sets: [(reps: 8, weight: 95),
                                         (reps: 8, weight: 175),
                                         (reps: 8, weight: 175)])
        let sets = session.entriesSorted[0].setsSorted
        sets[0].isWarmUp = true

        XCTAssertEqual(VolumeScore.score(for: sets[0], in: .pounds), 0)
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 2800,
                       "Only the two working sets should count")
    }

    func testABodyweightWarmUpAlsoScoresNothing() {
        let session = makeSession(makeTemplate("Core"), on: now,
                                  sets: [(reps: 20, weight: nil)])
        session.entriesSorted[0].setsSorted[0].isWarmUp = true
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 0)
    }

    /// The property defaults to false, so nothing logged before warm-ups existed changes
    /// score — which matters, because a shifting historical score would rewrite streaks.
    func testExistingSetsAreUnaffectedByDefault() {
        let session = makeSession(makeTemplate("Push"), on: now,
                                  sets: [(reps: 10, weight: 100)])
        XCTAssertFalse(session.entriesSorted[0].setsSorted[0].isWarmUp)
        XCTAssertEqual(VolumeScore.score(for: session, in: .pounds), 1000)
    }

    /// A warm-up must not be able to push someone over their target.
    func testWarmUpsCannotTriggerTheCelebration() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1000)

        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)
        model.addExercise(makeExercise("Bench"))
        let entry = session.entriesSorted[0]

        model.addSet(to: entry, reps: 5000, weight: nil, isWarmUp: true)
        XCTAssertEqual(model.liveScore, 0, "A warm-up adds nothing, however big")
        XCTAssertFalse(model.hasBeatenTarget)
        XCTAssertFalse(model.showCelebration)

        model.addSet(to: entry, reps: 1100, weight: nil)
        XCTAssertTrue(model.showCelebration, "A working set still counts normally")
    }

    func testMarkingALoggedSetAsWarmUpLowersTheScore() {
        let push = makeTemplate("Push")
        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)
        model.addExercise(makeExercise("Bench"))
        let entry = session.entriesSorted[0]

        let first = model.addSet(to: entry, reps: 10, weight: 100)
        model.addSet(to: entry, reps: 10, weight: 100)
        XCTAssertEqual(model.liveScore, 2000)

        model.updateSet(first, reps: 10, weight: 100, isWarmUp: true)
        XCTAssertEqual(model.liveScore, 1000)
    }

    func testRepeatLastTimeKeepsWarmUpsAsWarmUps() {
        let push = makeTemplate("Push")
        let bench = makeExercise("Bench")
        let previous = makeSession(push, on: VolumeTestCase.date(2026, 7, 15),
                                   sets: [(reps: 8, weight: 95), (reps: 8, weight: 175)],
                                   exercise: bench)
        previous.entriesSorted[0].setsSorted[0].isWarmUp = true

        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)
        model.repeatLastTime()

        let copied = model.session.entriesSorted[0].setsSorted
        XCTAssertTrue(copied[0].isWarmUp, "A warm-up repeated is still a warm-up")
        XCTAssertFalse(copied[1].isWarmUp)
        XCTAssertEqual(model.liveScore, model.scoreToBeat)
    }
}

@MainActor
final class DiscardWorkoutTests: VolumeTestCase {

    func testDiscardingRemovesTheWorkoutAndItsSets() {
        let push = makeTemplate("Push")
        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)
        model.addExercise(makeExercise("Bench"))
        model.addSet(to: session.entriesSorted[0], reps: 10, weight: 100)
        try? context.save()
        XCTAssertEqual(allSessions().count, 1)

        model.discard()
        try? context.save()

        XCTAssertTrue(allSessions().isEmpty, "A discarded workout leaves nothing behind")
        let strandedSets = (try? context.fetch(FetchDescriptor<SetEntry>())) ?? []
        XCTAssertTrue(strandedSets.isEmpty, "Deleting a session must cascade to its sets")
    }

    /// Deleting a workout has to recompute streaks, since nothing is cached.
    func testDeletingAWorkoutRestoresThePreviousComparison() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        let middle = makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)
        let latest = makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1200)
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2)

        context.delete(middle)
        try? context.save()

        XCTAssertEqual(SessionHistory.previousSession(for: latest, among: allSessions())?
                        .date, VolumeTestCase.date(2026, 7, 1))
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 1)
    }
}

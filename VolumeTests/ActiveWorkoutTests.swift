import XCTest
@testable import Volume

/// The celebration is the product. These cover when it fires, when it doesn't, and that
/// the streak it reports matches what Home will show afterwards.
@MainActor
final class ActiveWorkoutTests: VolumeTestCase {

    private func startWorkout(_ template: WorkoutTemplate,
                              mode: ActiveWorkoutMode = .live) -> ActiveWorkoutModel {
        let session = WorkoutSession(date: now, template: template)
        context.insert(session)
        return ActiveWorkoutModel(session: session, context: context, unit: .pounds, mode: mode)
    }

    private func addExercise(to model: ActiveWorkoutModel) -> ExerciseEntry {
        model.addExercise(makeExercise("Bench"))
        return model.session.entriesSorted[0]
    }

    func testCelebrationFiresOnTheSetThatCrossesTheTarget() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1000)

        let model = startWorkout(push)
        XCTAssertEqual(model.scoreToBeat, 1000)

        let entry = addExercise(to: model)

        model.addSet(to: entry, reps: 600, weight: nil)
        XCTAssertFalse(model.showCelebration, "600 < 1000, nothing yet")

        model.addSet(to: entry, reps: 399, weight: nil)
        XCTAssertFalse(model.showCelebration, "999 still isn't past 1000")

        model.addSet(to: entry, reps: 2, weight: nil)
        XCTAssertTrue(model.showCelebration, "1001 passes the target")
        XCTAssertTrue(model.hasBeatenTarget)
    }

    func testCelebrationFiresOnlyOncePerSession() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1000)

        let model = startWorkout(push)
        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 1200, weight: nil)
        XCTAssertTrue(model.showCelebration)

        // User dismisses it and keeps lifting.
        model.showCelebration = false
        model.addSet(to: entry, reps: 200, weight: nil)
        XCTAssertFalse(model.showCelebration, "Every later set must not re-trigger the celebration")
    }

    /// Backgrounding mid-workout and coming back must not replay a moment already had.
    func testResumingAnAlreadyBeatenSessionDoesNotReplayTheCelebration() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1000)

        let session = WorkoutSession(date: now, template: push)
        context.insert(session)
        let entry = ExerciseEntry(order: 0, exercise: makeExercise("Bench"))
        entry.session = session
        context.insert(entry)
        let set = SetEntry(order: 0, reps: 1500, weightValue: nil, unit: .pounds)
        set.entry = entry
        context.insert(set)

        let model = ActiveWorkoutModel(session: session, context: context, unit: .pounds)
        XCTAssertTrue(model.hasBeatenTarget)
        XCTAssertFalse(model.showCelebration)
    }

    func testEditingAPastWorkoutNeverCelebrates() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        let past = makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 500)

        let model = ActiveWorkoutModel(session: past, context: context,
                                       unit: .pounds, mode: .editingPast)
        let entry = past.entriesSorted[0]
        model.addSet(to: entry, reps: 5000, weight: nil)

        XCTAssertTrue(model.hasBeatenTarget)
        XCTAssertFalse(model.showCelebration, "Re-saving old history must stay silent")
    }

    func testFirstTimeDoingAWorkoutHasNoTargetAndNoCelebration() {
        let model = startWorkout(makeTemplate("Brand New"))
        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 9999, weight: nil)

        XCTAssertNil(model.scoreToBeat)
        XCTAssertFalse(model.hasBeatenTarget)
        XCTAssertFalse(model.showCelebration)
        XCTAssertEqual(model.progress, 0)
    }

    /// Every confetti moment must be worth exactly +1 on Home.
    func testProjectedStreakMatchesWhatHomeWillShow() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 1), score: 1000)
        makeSession(push, on: VolumeTestCase.date(2026, 7, 8), score: 1100)  // streak = 1

        let model = startWorkout(push)
        XCTAssertEqual(model.baseRecordStreak, 1)
        XCTAssertEqual(model.projectedStreak, 1, "Nothing logged yet")

        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 1200, weight: nil)
        XCTAssertEqual(model.projectedStreak, 2)

        let summary = model.finish()
        XCTAssertEqual(summary.recordStreak, 2)
        XCTAssertTrue(summary.didBeatTarget)
        XCTAssertEqual(summary.delta, 100)

        // And the real calculation agrees, with no double-count of the finished session.
        XCTAssertEqual(StreakCalculator.recordStreak(sessions: allSessions(), unit: .pounds), 2)
    }

    func testProgressRingOvershootsRatherThanClamping() {
        let push = makeTemplate("Push")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15), score: 1000)

        let model = startWorkout(push)
        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 1500, weight: nil)

        XCTAssertEqual(model.progress, 1.5, accuracy: 0.0001)
    }

    func testRepeatLastTimeCopiesEveryExerciseAndSet() {
        let push = makeTemplate("Push")
        let bench = makeExercise("Bench")
        makeSession(push, on: VolumeTestCase.date(2026, 7, 15),
                    sets: [(reps: 8, weight: 135), (reps: 8, weight: 135), (reps: 6, weight: 145)],
                    exercise: bench)

        let model = startWorkout(push)
        XCTAssertTrue(model.canRepeatLastTime)
        model.repeatLastTime()

        XCTAssertEqual(model.session.entriesSorted.count, 1)
        XCTAssertEqual(model.session.entriesSorted[0].setsSorted.map(\.reps), [8, 8, 6])
        XCTAssertEqual(model.liveScore, model.scoreToBeat)
        XCTAssertFalse(model.hasBeatenTarget, "Matching exactly is not beating")
    }

    func testFinishingAnEmptyWorkoutIsPreventedAndDiscardLeavesNoGhost() {
        let model = startWorkout(makeTemplate("Push"))
        XCTAssertTrue(model.isEmpty)

        model.discardIfEmpty()
        try? context.save()
        XCTAssertTrue(allSessions().isEmpty, "An abandoned empty workout must not appear in the calendar")
    }

    func testDeletingASetLowersTheScore() {
        let model = startWorkout(makeTemplate("Push"))
        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 10, weight: 100)
        model.addSet(to: entry, reps: 10, weight: 100)
        XCTAssertEqual(model.liveScore, 2000)

        model.deleteSet(entry.setsSorted[0])
        XCTAssertEqual(model.liveScore, 1000)
        XCTAssertEqual(entry.setsSorted.map(\.order), [0])
    }

    /// Deleting a middle set must renumber the rest, or the display shows "1, 3" and the
    /// next logged set collides with the survivor's order.
    func testDeletingAMiddleSetRenumbersTheRest() {
        let model = startWorkout(makeTemplate("Push"))
        let entry = addExercise(to: model)
        model.addSet(to: entry, reps: 8, weight: 100)
        model.addSet(to: entry, reps: 9, weight: 100)
        model.addSet(to: entry, reps: 10, weight: 100)

        model.deleteSet(entry.setsSorted[1])

        XCTAssertEqual(entry.setsSorted.map(\.order), [0, 1])
        XCTAssertEqual(entry.setsSorted.map(\.reps), [8, 10])

        model.addSet(to: entry, reps: 11, weight: 100)
        XCTAssertEqual(entry.setsSorted.map(\.order), [0, 1, 2])
        XCTAssertEqual(entry.setsSorted.map(\.reps), [8, 10, 11])
    }

    func testRemovingAMiddleExerciseRenumbersTheRest() {
        let model = startWorkout(makeTemplate("Push"))
        model.addExercise(makeExercise("Bench"))
        model.addExercise(makeExercise("Press"))
        model.addExercise(makeExercise("Fly"))

        model.removeExercise(model.session.entriesSorted[1])

        XCTAssertEqual(model.session.entriesSorted.map(\.order), [0, 1])
        XCTAssertEqual(model.session.entriesSorted.map(\.displayName), ["Bench", "Fly"])
    }
}

import Foundation
import SwiftData
import SwiftUI

/// A snapshot of how a workout went, taken at the moment it's finished.
struct WorkoutSummary {
    let templateName: String
    let score: Double
    /// `nil` the first time this template was performed.
    let previousScore: Double?
    let didBeatTarget: Bool
    let recordStreak: Int
    let totalSets: Int
    let exerciseCount: Int

    var delta: Double? {
        guard let previousScore else { return nil }
        return score - previousScore
    }

    var percentDelta: Double? {
        guard let previousScore else { return nil }
        return VolumeScore.percentDelta(new: score, old: previousScore)
    }
}

enum ActiveWorkoutMode {
    /// A workout happening right now: live target, milestones, celebration.
    case live
    /// Fixing up a workout from the calendar. Same editor, but silent — re-saving an old
    /// session must never fire confetti for a record that was set weeks ago.
    case editingPast
}

/// Drives a workout in progress: the live score, the target, and the celebration.
///
/// Score evaluation is triggered explicitly from each mutation rather than observed from
/// the outside, so the celebration fires exactly once, at the exact moment a set pushes
/// the score past the target — never on a re-render, never twice.
@MainActor
@Observable
final class ActiveWorkoutModel {

    let session: WorkoutSession
    let mode: ActiveWorkoutMode
    private let context: ModelContext
    var unit: WeightUnit

    private(set) var previousSession: WorkoutSession?
    /// Record streak *before* this session, so `projectedStreak` can show the user the
    /// number they'll land on.
    private(set) var baseRecordStreak = 0

    var showCelebration = false
    private(set) var didCelebrate = false
    private var milestonesReached: Set<Int> = []

    /// Bumped on every mutation, and read by the workout views.
    ///
    /// SwiftData does not reliably notify observers of a to-many relationship when it
    /// changes — a newly logged set landed in the store but the exercise card kept
    /// rendering its old list until some unrelated tap forced a redraw. Reading this in
    /// `body` guarantees the redraw happens the instant a set is logged.
    private(set) var changeCount = 0

    init(session: WorkoutSession,
         context: ModelContext,
         unit: WeightUnit,
         mode: ActiveWorkoutMode = .live) {
        self.session = session
        self.context = context
        self.unit = unit
        self.mode = mode
        refreshHistory()

        // Resuming a session that already passed its target must not re-fire the
        // celebration — the user has already had that moment. Same for editing history.
        if hasBeatenTarget || mode == .editingPast {
            didCelebrate = true
            milestonesReached = [25, 50, 75]
        }
    }

    // MARK: - Derived state

    var liveScore: Double {
        VolumeScore.score(for: session, in: unit)
    }

    /// `nil` the first time a template is performed — there is genuinely nothing to beat,
    /// so the UI shows no ring and just lets the score build.
    var scoreToBeat: Double? {
        guard let previousSession else { return nil }
        let score = VolumeScore.score(for: previousSession, in: unit)
        return score > 0 ? score : nil
    }

    var progress: Double {
        guard let target = scoreToBeat else { return 0 }
        return liveScore / target
    }

    var hasBeatenTarget: Bool {
        guard let target = scoreToBeat else { return false }
        return liveScore > target
    }

    var delta: Double? {
        guard let target = scoreToBeat else { return nil }
        return liveScore - target
    }

    var projectedStreak: Int {
        baseRecordStreak + (hasBeatenTarget ? 1 : 0)
    }

    var isEmpty: Bool {
        session.entriesSorted.allSatisfy { $0.setsSorted.isEmpty }
    }

    var canRepeatLastTime: Bool {
        previousSession != nil && session.entriesSorted.isEmpty
    }

    /// What this exercise scored last time, so overload is visible per exercise and not
    /// only across the whole workout. `nil` when it wasn't performed last time.
    func lastTimeScore(for entry: ExerciseEntry) -> Double? {
        guard let previous = lastTime(for: entry) else { return nil }
        let score = VolumeScore.score(for: previous, in: unit)
        return score > 0 ? score : nil
    }

    /// The same exercise in the previous session of this template, if it was performed.
    /// Used to pre-fill the next set and to show "Last time: 8 × 135 lb" — a statement of
    /// what happened, never a suggestion of what to do.
    func lastTime(for entry: ExerciseEntry) -> ExerciseEntry? {
        guard let previousSession else { return nil }
        return previousSession.entriesSorted.first { candidate in
            if let candidateExercise = candidate.exercise, let entryExercise = entry.exercise {
                return candidateExercise.persistentModelID == entryExercise.persistentModelID
            }
            return candidate.displayName.caseInsensitiveCompare(entry.displayName) == .orderedSame
        }
    }

    // MARK: - Mutations

    func addExercise(_ exercise: Exercise) {
        let entry = ExerciseEntry(order: session.entriesSorted.count, exercise: exercise)
        context.insert(entry)
        // Assign through the parent's array rather than only setting `entry.session`.
        // SwiftData keeps both sides in sync either way, but writing the parent side is
        // what actually notifies views observing `session.entries`.
        session.entries = (session.entries ?? []) + [entry]
        Haptics.tap()
        commit()
    }

    func addCustomExercise(named name: String, isBodyweight: Bool) -> Exercise {
        let exercise = Exercise(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                category: "Custom",
                                isBodyweight: isBodyweight,
                                isCustom: true)
        context.insert(exercise)
        addExercise(exercise)
        return exercise
    }

    func removeExercise(_ entry: ExerciseEntry) {
        // Survivors are captured *before* the delete: a deleted object still shows up in
        // its parent's relationship until the context processes the change, so
        // reindexing afterwards would count the corpse and skip a number.
        let survivors = session.entriesSorted.filter {
            $0.persistentModelID != entry.persistentModelID
        }
        session.entries = survivors
        context.delete(entry)
        for (index, remaining) in survivors.enumerated() {
            remaining.order = index
        }
        commit()
    }

    @discardableResult
    func addSet(to entry: ExerciseEntry,
                reps: Int,
                weight: Double?,
                isWarmUp: Bool = false) -> SetEntry {
        let set = SetEntry(order: entry.nextSetOrder,
                           reps: max(reps, 0),
                           weightValue: weight,
                           unit: unit,
                           isWarmUp: isWarmUp)
        context.insert(set)
        entry.sets = (entry.sets ?? []) + [set]
        Haptics.setLogged()
        commit()
        return set
    }

    /// Moves the workout in time. Clamped to now, and history is refreshed because the
    /// date determines which session this one is measured against.
    func updateDate(_ date: Date) {
        session.date = min(date, Date())
        commit()
        refreshHistory()
    }

    func updateSet(_ set: SetEntry, reps: Int, weight: Double?, isWarmUp: Bool) {
        set.reps = max(reps, 0)
        set.weightValue = weight
        set.weightUnitRaw = unit.rawValue
        set.isWarmUp = isWarmUp
        commit()
    }

    func deleteSet(_ set: SetEntry) {
        // Same ordering trap as `removeExercise` — snapshot the survivors first, or set 3
        // stays numbered 3 after set 2 is deleted and the next logged set collides with it.
        let parent = set.entry
        let survivors = (parent?.setsSorted ?? []).filter {
            $0.persistentModelID != set.persistentModelID
        }
        parent?.sets = survivors
        context.delete(set)
        for (index, remaining) in survivors.enumerated() {
            remaining.order = index
        }
        commit()
    }

    /// Pre-fills every exercise and set from the previous session of this template, so a
    /// repeat workout is "edit the numbers" rather than "build it again".
    func repeatLastTime() {
        guard let previousSession else { return }
        for sourceEntry in previousSession.entriesSorted {
            let entry = ExerciseEntry(order: session.entriesSorted.count,
                                      exercise: sourceEntry.exercise)
            entry.nameSnapshot = sourceEntry.nameSnapshot
            entry.isBodyweight = sourceEntry.isBodyweight
            context.insert(entry)
            session.entries = (session.entries ?? []) + [entry]

            var copiedSets: [SetEntry] = []
            for sourceSet in sourceEntry.setsSorted {
                let set = SetEntry(order: sourceSet.order,
                                   reps: sourceSet.reps,
                                   weightValue: sourceSet.weight(in: unit),
                                   unit: unit,
                                   isWarmUp: sourceSet.isWarmUp)
                context.insert(set)
                copiedSets.append(set)
            }
            entry.sets = copiedSets
        }
        Haptics.setLogged()
        commit()
    }

    /// Completes the session and returns everything the summary screen needs.
    ///
    /// The summary is captured *before* history is refreshed. Once this session counts as
    /// completed it becomes part of the streak calculation, so reading `projectedStreak`
    /// afterwards would count it twice.
    @discardableResult
    func finish() -> WorkoutSummary {
        let summary = WorkoutSummary(templateName: session.displayName,
                                     score: liveScore,
                                     previousScore: scoreToBeat,
                                     didBeatTarget: hasBeatenTarget,
                                     recordStreak: projectedStreak,
                                     totalSets: session.totalSets,
                                     exerciseCount: session.entriesSorted.count)

        session.isCompleted = true
        session.endedAt = Date()
        if session.templateNameSnapshot.isEmpty {
            session.templateNameSnapshot = session.template?.name ?? "Workout"
        }
        save()

        if summary.didBeatTarget {
            Haptics.newRecord()
        } else {
            Haptics.finished()
        }
        refreshHistory()
        return summary
    }

    /// Abandoning a session that never had a set logged shouldn't leave a ghost in the
    /// calendar.
    func discardIfEmpty() {
        guard !session.isCompleted, isEmpty else { return }
        context.delete(session)
        save()
    }

    /// Throws the whole workout away, sets and all. Deleting a session cascades to its
    /// exercises and sets, so nothing is orphaned.
    func discard() {
        context.delete(session)
        save()
        Haptics.warning()
    }

    // MARK: - Score evaluation

    private func commit() {
        changeCount += 1
        save()
        evaluateScore()
    }

    private func evaluateScore() {
        guard let target = scoreToBeat, target > 0 else { return }
        let score = liveScore

        if !didCelebrate, score > target {
            didCelebrate = true
            milestonesReached = [25, 50, 75]
            Haptics.newRecord()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                showCelebration = true
            }
            return
        }

        for milestone in [25, 50, 75] where !milestonesReached.contains(milestone) {
            if score >= target * Double(milestone) / 100 {
                milestonesReached.insert(milestone)
                Haptics.milestone()
            }
        }
    }

    private func refreshHistory() {
        let all = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        previousSession = SessionHistory.previousSession(for: session, among: all)
        // `recordStreak` only counts completed sessions, so the in-progress one is
        // naturally excluded from the base.
        baseRecordStreak = StreakCalculator.recordStreak(sessions: all, unit: unit)
    }

    private func save() {
        try? context.save()
    }
}

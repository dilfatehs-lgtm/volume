import Foundation
import SwiftData

// MARK: - CloudKit ground rules
//
// Every model below obeys three constraints imposed by CloudKit mirroring. Breaking any
// of them fails at `ModelContainer` init — at runtime, not compile time:
//
//   1. No `@Attribute(.unique)` anywhere. (Hence slug-based de-duplication in
//      `ExerciseLibrary` instead of a unique constraint.)
//   2. Every property is optional or has a default value.
//   3. Every relationship is optional and has an explicit inverse, declared on exactly
//      one side.
//
// Delete rules are chosen so the log is never destroyed: deleting a template or a
// library exercise nullifies the link and leaves history intact, readable via the
// name snapshots. Only deleting a session — an explicit "remove this workout" — cascades.

/// Identifies which past sessions a session should be compared against.
///
/// Normally the template's identity, so renaming "Leg Day" keeps its history. Falls back
/// to the snapshotted name for sessions whose template was deleted, so those still group
/// together instead of each becoming an orphan.
enum SessionComparisonKey: Hashable {
    case model(PersistentIdentifier)
    case name(String)
}

// MARK: - Exercise

@Model
final class Exercise {
    var name: String = ""
    /// Stable identifier for shipped presets, and the key duplicate library entries are
    /// collapsed on. Empty for user-created exercises.
    var slug: String = ""
    var category: String = ""
    var isBodyweight: Bool = false
    var isCustom: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \ExerciseEntry.exercise)
    var entries: [ExerciseEntry]? = []

    init(name: String,
         slug: String = "",
         category: String = "",
         isBodyweight: Bool = false,
         isCustom: Bool = false,
         createdAt: Date = Date()) {
        self.name = name
        self.slug = slug
        self.category = category
        self.isBodyweight = isBodyweight
        self.isCustom = isCustom
        self.createdAt = createdAt
    }
}

// MARK: - WorkoutTemplate

@Model
final class WorkoutTemplate {
    var name: String = ""
    var createdAt: Date = Date()

    /// Nullify, not cascade: deleting a template must never delete the workouts you did.
    /// Those sessions keep `templateNameSnapshot` and stay readable in the calendar.
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.template)
    var sessions: [WorkoutSession]? = []

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }

    var completedSessions: [WorkoutSession] {
        (sessions ?? []).filter(\.isCompleted).sorted { $0.date > $1.date }
    }
}

// MARK: - WorkoutSession

@Model
final class WorkoutSession {
    var date: Date = Date()
    var endedAt: Date?
    var isCompleted: Bool = false
    /// Frozen at creation so a past workout stays readable after its template is renamed
    /// or deleted. Historical logs must never silently change.
    var templateNameSnapshot: String = ""
    var template: WorkoutTemplate?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.session)
    var entries: [ExerciseEntry]? = []

    init(date: Date = Date(),
         template: WorkoutTemplate? = nil,
         isCompleted: Bool = false) {
        self.date = date
        self.template = template
        self.templateNameSnapshot = template?.name ?? ""
        self.isCompleted = isCompleted
    }

    var entriesSorted: [ExerciseEntry] {
        (entries ?? []).sorted { $0.order < $1.order }
    }

    var displayName: String {
        let live = template?.name ?? ""
        return live.isEmpty ? templateNameSnapshot : live
    }

    var comparisonKey: SessionComparisonKey {
        if let template { return .model(template.persistentModelID) }
        return .name(templateNameSnapshot.lowercased())
    }

    var totalSets: Int {
        entriesSorted.reduce(0) { $0 + $1.setsSorted.count }
    }
}

// MARK: - ExerciseEntry

@Model
final class ExerciseEntry {
    var order: Int = 0
    /// Frozen name, for the same reason as `templateNameSnapshot`.
    var nameSnapshot: String = ""
    var isBodyweight: Bool = false
    var exercise: Exercise?
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.entry)
    var sets: [SetEntry]? = []

    init(order: Int = 0, exercise: Exercise? = nil) {
        self.order = order
        self.exercise = exercise
        self.nameSnapshot = exercise?.name ?? ""
        self.isBodyweight = exercise?.isBodyweight ?? false
    }

    var setsSorted: [SetEntry] {
        (sets ?? []).sorted { $0.order < $1.order }
    }

    var displayName: String {
        let live = exercise?.name ?? ""
        return live.isEmpty ? nameSnapshot : live
    }

    var nextSetOrder: Int {
        (setsSorted.last?.order ?? -1) + 1
    }
}

// MARK: - SetEntry

@Model
final class SetEntry {
    var order: Int = 0
    var reps: Int = 0
    /// `nil` means bodyweight — the set contributes its reps alone to the score.
    var weightValue: Double?
    /// The unit this weight was *typed* in, stored alongside it so the number never
    /// drifts through a conversion round-trip.
    var weightUnitRaw: String = WeightUnit.pounds.rawValue
    var loggedAt: Date = Date()
    var entry: ExerciseEntry?

    init(order: Int = 0,
         reps: Int = 0,
         weightValue: Double? = nil,
         unit: WeightUnit = .pounds,
         loggedAt: Date = Date()) {
        self.order = order
        self.reps = reps
        self.weightValue = weightValue
        self.weightUnitRaw = unit.rawValue
        self.loggedAt = loggedAt
    }

    var unit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .pounds
    }

    var hasWeight: Bool {
        if let weightValue { return weightValue > 0 }
        return false
    }

    /// The stored weight expressed in some other unit, for display.
    func weight(in unit: WeightUnit) -> Double? {
        guard let weightValue else { return nil }
        return self.unit.convert(weightValue, to: unit)
    }
}

// MARK: - WeeklyGoal

/// One entry per goal *change*, never overwritten — see
/// `StreakCalculator.goal(forWeekStarting:goals:)` for why history matters here.
@Model
final class WeeklyGoal {
    var daysPerWeek: Int = StreakCalculator.defaultWeeklyGoal
    /// Always normalised to the start of the week the change was made in, so the copy
    /// "Applies from this week onward" is literally true.
    var effectiveFrom: Date = Date()

    init(daysPerWeek: Int, effectiveFrom: Date) {
        self.daysPerWeek = daysPerWeek
        self.effectiveFrom = effectiveFrom
    }
}

extension WeeklyGoal {
    /// Records a new goal from this week forward. Changing your mind twice in the same
    /// week updates that week's record rather than piling up entries.
    @discardableResult
    static func setGoal(_ days: Int,
                        in context: ModelContext,
                        calendar: Calendar = .current,
                        now: Date = Date()) -> WeeklyGoal {
        let clamped = min(max(days, StreakCalculator.goalRange.lowerBound),
                          StreakCalculator.goalRange.upperBound)
        let effective = StreakCalculator.weekStart(for: now, calendar: calendar)
        let existing = (try? context.fetch(FetchDescriptor<WeeklyGoal>())) ?? []

        if let thisWeek = existing.first(where: { $0.effectiveFrom == effective }) {
            thisWeek.daysPerWeek = clamped
            return thisWeek
        }
        let goal = WeeklyGoal(daysPerWeek: clamped, effectiveFrom: effective)
        context.insert(goal)
        return goal
    }
}

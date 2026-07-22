#if DEBUG
import Foundation
import SwiftData

/// Ten weeks of plausible history so the calendar, chart and streaks have something to
/// show the moment the app is first run. DEBUG only — never compiled into a release
/// build. Loaded from Settings ▸ Developer.
///
/// The data is deliberately shaped to exercise the interesting cases:
///   • Push / Pull / Legs interleaved, so per-template comparison is visibly correct.
///   • Two dips early in each workout's history, so streaks have something to reset on
///     without leaving the current streak at zero.
///   • Two bodyweight exercises, so reps-only scoring is represented.
///   • The current week left partially complete, so "2 / 3 this week" shows an
///     in-progress week that hasn't broken the streak.
enum SampleData {

    private struct Plan {
        let template: String
        /// slug, reps, sets, base weight in pounds (nil = bodyweight)
        let exercises: [(slug: String, reps: Int, sets: Int, baseLb: Double?)]
    }

    private static let plans: [Plan] = [
        Plan(template: "Push", exercises: [
            ("barbell-bench-press", 8, 3, 135),
            ("incline-dumbbell-press", 10, 3, 50),
            ("overhead-press", 8, 3, 85),
            ("lateral-raise", 12, 3, 15),
            ("triceps-pushdown", 12, 3, 50),
            ("push-up", 15, 2, nil),
        ]),
        Plan(template: "Pull", exercises: [
            ("deadlift", 5, 3, 225),
            ("lat-pulldown", 10, 3, 120),
            ("barbell-row", 8, 3, 115),
            ("hammer-curl", 10, 3, 30),
            ("face-pull", 15, 3, 40),
            ("pull-up", 8, 2, nil),
        ]),
        Plan(template: "Legs", exercises: [
            ("back-squat", 6, 3, 185),
            ("romanian-deadlift", 8, 3, 155),
            ("leg-press", 10, 3, 270),
            ("leg-curl", 12, 3, 90),
            ("calf-raise", 15, 3, 110),
        ]),
    ]

    @MainActor
    static func populate(in context: ModelContext,
                         unit: WeightUnit = .pounds,
                         now: Date = Date(),
                         calendar: Calendar = .current) {
        let existing = (try? context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []
        guard existing.isEmpty else { return }

        let exercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        let bySlug = Dictionary(exercises.compactMap { $0.slug.isEmpty ? nil : ($0.slug, $0) },
                                uniquingKeysWith: { first, _ in first })
        guard !bySlug.isEmpty else { return }

        let templates = plans.map { plan -> WorkoutTemplate in
            let template = WorkoutTemplate(name: plan.template,
                                           createdAt: calendar.date(byAdding: .weekOfYear,
                                                                    value: -10, to: now) ?? now)
            context.insert(template)
            return template
        }

        var occurrences = [String: Int]()
        let thisWeekStart = StreakCalculator.weekStart(for: now, calendar: calendar)

        // Weeks 10 → 1: three workouts each. Week 0 (current): left incomplete on purpose.
        var dates: [Date] = []
        for weeksAgo in stride(from: 10, through: 1, by: -1) {
            guard let anchor = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now) else {
                continue
            }
            let weekStart = StreakCalculator.weekStart(for: anchor, calendar: calendar)
            for dayOffset in [1, 3, 5] {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                   let stamped = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: day) {
                    dates.append(stamped)
                }
            }
        }
        for daysAgo in [3, 1] {
            if let day = calendar.date(byAdding: .day, value: -daysAgo, to: now),
               day >= thisWeekStart,
               let stamped = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: day) {
                dates.append(stamped)
            }
        }

        for (index, date) in dates.sorted().enumerated() {
            let plan = plans[index % plans.count]
            let template = templates[index % templates.count]
            let occurrence = occurrences[plan.template, default: 0]
            occurrences[plan.template] = occurrence + 1

            let session = WorkoutSession(date: date, template: template, isCompleted: true)
            session.endedAt = calendar.date(byAdding: .minute, value: 52, to: date)
            context.insert(session)

            for (order, spec) in plan.exercises.enumerated() {
                guard let exercise = bySlug[spec.slug] else { continue }
                let entry = ExerciseEntry(order: order, exercise: exercise)
                entry.session = session
                context.insert(entry)

                for setIndex in 0..<spec.sets {
                    let set = SetEntry(order: setIndex,
                                       reps: spec.reps,
                                       weightValue: weight(for: spec.baseLb,
                                                           occurrence: occurrence,
                                                           in: unit),
                                       unit: unit,
                                       loggedAt: date)
                    set.entry = entry
                    context.insert(set)
                }
            }
        }

        try? context.save()
    }

    /// Progressive overload with two stumbles early on.
    ///
    /// The dips are pinned to specific early sessions rather than a repeating modulo so
    /// they can't land on the most recent workouts — otherwise a freshly seeded demo opens
    /// with a record streak of zero, which is a poor look for the app's hero stat. History
    /// still contains resets, so "best ever" is meaningfully higher than nothing.
    private static func weight(for baseLb: Double?, occurrence: Int, in unit: WeightUnit) -> Double? {
        guard let baseLb else { return nil }
        let stepLb: Double = baseLb >= 100 ? 5 : 2.5
        var valueLb = baseLb + Double(occurrence) * stepLb
        if occurrence == 3 || occurrence == 6 { valueLb -= stepLb * 2 }

        let converted = WeightUnit.pounds.convert(valueLb, to: unit)
        // Snap to a weight a person could actually load.
        let increment = unit.step / 2
        return (converted / increment).rounded() * increment
    }

    @MainActor
    static func clearAll(in context: ModelContext) {
        VolumeStore.eraseEverything(in: context)
    }
}
#endif

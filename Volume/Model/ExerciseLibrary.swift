import Foundation
import SwiftData

/// The exercises shipped with the app, and the logic that keeps the library clean.
///
/// Deliberately resistance-only. Cardio machines don't fit a `reps × weight` score —
/// "one rep of treadmill" is meaningless — and including them would put entries in the
/// library that quietly produce nonsense scores. Users who want them can still add a
/// custom exercise.
enum ExerciseLibrary {

    struct Preset {
        let slug: String
        let name: String
        let category: String
        let isBodyweight: Bool

        init(_ slug: String, _ name: String, _ category: String, bodyweight: Bool = false) {
            self.slug = slug
            self.name = name
            self.category = category
            self.isBodyweight = bodyweight
        }
    }

    /// Section order in the picker. Not a training taxonomy — purely so a 53-item list
    /// is browsable without scrolling past everything.
    static let categoryOrder = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Custom"]

    static let presets: [Preset] = [
        // Chest
        Preset("barbell-bench-press", "Barbell Bench Press", "Chest"),
        Preset("incline-barbell-bench-press", "Incline Barbell Bench Press", "Chest"),
        Preset("dumbbell-bench-press", "Dumbbell Bench Press", "Chest"),
        Preset("incline-dumbbell-press", "Incline Dumbbell Press", "Chest"),
        Preset("chest-fly-machine", "Chest Fly (Machine)", "Chest"),
        Preset("cable-crossover", "Cable Crossover", "Chest"),
        Preset("push-up", "Push-Up", "Chest", bodyweight: true),
        Preset("dip", "Dip", "Chest", bodyweight: true),

        // Back
        Preset("deadlift", "Deadlift", "Back"),
        Preset("barbell-row", "Barbell Row", "Back"),
        Preset("dumbbell-row", "Dumbbell Row", "Back"),
        Preset("lat-pulldown", "Lat Pulldown", "Back"),
        Preset("seated-cable-row", "Seated Cable Row", "Back"),
        Preset("t-bar-row", "T-Bar Row", "Back"),
        Preset("face-pull", "Face Pull", "Back"),
        Preset("straight-arm-pulldown", "Straight-Arm Pulldown", "Back"),
        Preset("pull-up", "Pull-Up", "Back", bodyweight: true),
        Preset("chin-up", "Chin-Up", "Back", bodyweight: true),

        // Legs
        Preset("back-squat", "Back Squat", "Legs"),
        Preset("front-squat", "Front Squat", "Legs"),
        Preset("goblet-squat", "Goblet Squat", "Legs"),
        Preset("leg-press", "Leg Press", "Legs"),
        Preset("romanian-deadlift", "Romanian Deadlift", "Legs"),
        Preset("leg-extension", "Leg Extension", "Legs"),
        Preset("leg-curl", "Leg Curl", "Legs"),
        Preset("walking-lunge", "Walking Lunge", "Legs"),
        Preset("bulgarian-split-squat", "Bulgarian Split Squat", "Legs"),
        Preset("calf-raise", "Calf Raise", "Legs"),
        Preset("hip-thrust", "Hip Thrust", "Legs"),

        // Shoulders
        Preset("overhead-press", "Overhead Press", "Shoulders"),
        Preset("dumbbell-shoulder-press", "Dumbbell Shoulder Press", "Shoulders"),
        Preset("arnold-press", "Arnold Press", "Shoulders"),
        Preset("lateral-raise", "Lateral Raise", "Shoulders"),
        Preset("front-raise", "Front Raise", "Shoulders"),
        Preset("rear-delt-fly", "Rear Delt Fly", "Shoulders"),
        Preset("upright-row", "Upright Row", "Shoulders"),
        Preset("shrug", "Shrug", "Shoulders"),

        // Arms
        Preset("barbell-curl", "Barbell Curl", "Arms"),
        Preset("dumbbell-curl", "Dumbbell Curl", "Arms"),
        Preset("hammer-curl", "Hammer Curl", "Arms"),
        Preset("preacher-curl", "Preacher Curl", "Arms"),
        Preset("cable-curl", "Cable Curl", "Arms"),
        Preset("triceps-pushdown", "Triceps Pushdown", "Arms"),
        Preset("overhead-triceps-extension", "Overhead Triceps Extension", "Arms"),
        Preset("skull-crusher", "Skull Crusher", "Arms"),
        Preset("close-grip-bench-press", "Close-Grip Bench Press", "Arms"),

        // Core
        Preset("plank", "Plank", "Core", bodyweight: true),
        Preset("hanging-leg-raise", "Hanging Leg Raise", "Core", bodyweight: true),
        Preset("crunch", "Crunch", "Core", bodyweight: true),
        Preset("sit-up", "Sit-Up", "Core", bodyweight: true),
        Preset("russian-twist", "Russian Twist", "Core", bodyweight: true),
        Preset("ab-wheel-rollout", "Ab Wheel Rollout", "Core", bodyweight: true),
        Preset("cable-crunch", "Cable Crunch", "Core"),
    ]

    /// Idempotent: inserts only the presets that are missing, and collapses duplicates.
    ///
    /// This can't be a one-shot `hasSeeded` flag. CloudKit forbids unique constraints, so
    /// a second device syncing an already-seeded library would happily insert its own
    /// full copy and leave the user with two of every exercise. Matching on `slug` and
    /// sweeping duplicates on every launch is what actually keeps the library clean.
    @MainActor
    static func seed(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []

        var keptBySlug: [String: Exercise] = [:]
        var duplicates: [Exercise] = []

        // Oldest wins, so every device independently converges on the same survivor.
        for exercise in existing.sorted(by: { $0.createdAt < $1.createdAt }) {
            guard !exercise.slug.isEmpty else { continue }  // custom exercises are never merged
            if let kept = keptBySlug[exercise.slug] {
                for entry in exercise.entries ?? [] {
                    entry.exercise = kept
                }
                duplicates.append(exercise)
            } else {
                keptBySlug[exercise.slug] = exercise
            }
        }

        for duplicate in duplicates {
            context.delete(duplicate)
        }

        for preset in presets where keptBySlug[preset.slug] == nil {
            context.insert(Exercise(name: preset.name,
                                    slug: preset.slug,
                                    category: preset.category,
                                    isBodyweight: preset.isBodyweight,
                                    isCustom: false))
        }

        try? context.save()
    }
}

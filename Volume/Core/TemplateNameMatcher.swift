import Foundation

/// Spots when a new workout name probably means the same thing as an existing one.
///
/// Because every comparison in the app is per-template, a user who logs "Leg Day" for
/// months and then creates "Legs" silently resets their own score to beat. This can't be
/// solved with a muscle-group taxonomy — that would put a classification system in front
/// of someone naming "Maria's Tuesday Workout". A naming nudge fixes the actual failure
/// without any of that.
enum TemplateNameMatcher {

    /// Words that describe *that* it's a workout rather than *which* workout it is.
    private static let stopwords: Set<String> = [
        "day", "days", "workout", "workouts", "session", "sessions",
        "training", "train", "the", "my", "a",
    ]

    static func tokens(_ name: String) -> Set<String> {
        let words = name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map(singularise)
            .filter { !stopwords.contains($0) }
        return Set(words)
    }

    /// True when one name's meaningful words are contained in the other's.
    ///
    /// "Leg Day" ≈ "Legs" (both reduce to `leg`), "Upper" ≈ "Upper Body" (subset), while
    /// "Push" and "Pull" stay distinct.
    static func areSimilar(_ lhs: String, _ rhs: String) -> Bool {
        let left = tokens(lhs)
        let right = tokens(rhs)
        guard !left.isEmpty, !right.isEmpty else {
            return lhs.compare(rhs, options: .caseInsensitive) == .orderedSame
        }
        return left.isSubset(of: right) || right.isSubset(of: left)
    }

    static func firstMatch(for name: String, in templates: [WorkoutTemplate]) -> WorkoutTemplate? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return templates.first { areSimilar($0.name, trimmed) }
    }

    private static func singularise(_ word: String) -> String {
        guard word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") else { return word }
        return String(word.dropLast())
    }
}

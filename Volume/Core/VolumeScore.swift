import Foundation

/// The one and only place a volume score is calculated.
///
/// Per set: `reps × weight`. A set with no weight (bodyweight) contributes its `reps`
/// alone. A session is the sum of every set across every exercise.
///
/// Every score in the app — the live score, the score to beat, the calendar, the chart,
/// the streak — is computed in the user's *current* display unit. Flipping lb↔kg
/// rescales all of them by the same factor, so "did I beat last time" can never be
/// wrong just because the user changed a setting.
enum VolumeScore {

    static func score(for set: SetEntry, in unit: WeightUnit) -> Double {
        guard let weight = set.weightValue, weight > 0 else {
            return Double(set.reps)
        }
        return Double(set.reps) * set.unit.convert(weight, to: unit)
    }

    static func score(for entry: ExerciseEntry, in unit: WeightUnit) -> Double {
        entry.setsSorted.reduce(0) { $0 + score(for: $1, in: unit) }
    }

    static func score(for session: WorkoutSession, in unit: WeightUnit) -> Double {
        session.entriesSorted.reduce(0) { $0 + score(for: $1, in: unit) }
    }

    // MARK: - Formatting

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.roundingMode = .halfUp
        return f
    }()

    /// Grouped, no decimals — "12,480". Scores get large fast and decimals add noise.
    static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Signed form for deltas — "+2,340" / "−820".
    static func formatDelta(_ value: Double) -> String {
        let magnitude = format(abs(value))
        if value > 0 { return "+\(magnitude)" }
        if value < 0 { return "−\(magnitude)" }
        return magnitude
    }

    /// Percentage change against a previous score, nil when there's nothing to compare.
    static func percentDelta(new: Double, old: Double) -> Double? {
        guard old > 0 else { return nil }
        return (new - old) / old * 100
    }
}

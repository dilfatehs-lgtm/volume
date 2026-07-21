import Foundation

/// The unit a weight was entered in.
///
/// Weights are stored exactly as the user typed them, alongside the unit they typed
/// them in — never canonicalised to a single unit. Typing `135 lb` and reading it back
/// always gives `135 lb`, with no floating-point round-trip drift. Conversion happens
/// only when displaying or scoring.
enum WeightUnit: String, CaseIterable, Identifiable, Codable, Sendable {
    case pounds = "lb"
    case kilograms = "kg"

    var id: String { rawValue }

    /// Short suffix shown next to numbers, e.g. "135 lb".
    var shortName: String { rawValue }

    var displayName: String {
        switch self {
        case .pounds: "Pounds (lb)"
        case .kilograms: "Kilograms (kg)"
        }
    }

    /// Spoken form, so VoiceOver says "135 pounds" rather than "135 ell bee".
    var spokenName: String {
        switch self {
        case .pounds: "pounds"
        case .kilograms: "kilograms"
        }
    }

    /// The amount the +/- buttons move by. Matches the smallest plate people
    /// actually add in each unit.
    var step: Double {
        switch self {
        case .pounds: 5
        case .kilograms: 2.5
        }
    }

    private static let kilogramsPerPound = 0.45359237

    func convert(_ value: Double, to other: WeightUnit) -> Double {
        guard self != other else { return value }
        switch (self, other) {
        case (.pounds, .kilograms): return value * Self.kilogramsPerPound
        case (.kilograms, .pounds): return value / Self.kilogramsPerPound
        default: return value
        }
    }

    /// The user's locale's likely preference, used only as the very first default.
    static var localeDefault: WeightUnit {
        Locale.current.measurementSystem == .us ? .pounds : .kilograms
    }
}

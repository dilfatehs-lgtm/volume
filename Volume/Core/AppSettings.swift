import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var iconName: String {
        switch self {
        case .automatic: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    /// `nil` for Automatic — deliberately, so the system keeps control and a device
    /// that switches to dark (on a schedule, or via Control Centre) is followed live
    /// without the app doing any work. Returning the currently-detected scheme here
    /// instead would freeze the app on whatever it was at launch.
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// User preferences. Small enough to live in `UserDefaults`; none of this is
/// workout data, so none of it needs to sync.
@Observable
final class AppSettings {

    static let shared = AppSettings()

    private enum Key {
        static let appearance = "settings.appearance"
        static let unit = "settings.unit"
        static let onboardingComplete = "settings.onboardingComplete"
        static let debugUnlocked = "settings.debugUnlocked"
    }

    private let defaults: UserDefaults

    var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    var unit: WeightUnit {
        didSet { defaults.set(unit.rawValue, forKey: Key.unit) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.onboardingComplete) }
    }

    /// DEBUG-only escape hatch so the paywall can't block development builds.
    /// Never consulted in release builds — see `SubscriptionManager.hasAccess`.
    var debugUnlocked: Bool {
        didSet { defaults.set(debugUnlocked, forKey: Key.debugUnlocked) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAppearance = defaults.string(forKey: Key.appearance)
        self.appearance = storedAppearance.flatMap(AppearanceMode.init(rawValue:)) ?? .automatic
        let storedUnit = defaults.string(forKey: Key.unit)
        self.unit = storedUnit.flatMap(WeightUnit.init(rawValue:)) ?? .localeDefault
        self.hasCompletedOnboarding = defaults.bool(forKey: Key.onboardingComplete)
        self.debugUnlocked = defaults.bool(forKey: Key.debugUnlocked)
    }

    func resetForOnboarding() {
        hasCompletedOnboarding = false
    }

    /// Everything back to first-launch values.
    ///
    /// Clearing `hasCompletedOnboarding` is what actually restarts the experience —
    /// `RootView` observes it and swaps straight back to the welcome screen. iOS apps
    /// can't relaunch themselves, and don't need to.
    func resetToDefaults() {
        appearance = .automatic
        unit = .localeDefault
        debugUnlocked = false
        hasCompletedOnboarding = false
    }
}

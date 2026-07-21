import SwiftData
import SwiftUI

/// Decides what the user sees: onboarding, the app, or a wall.
struct RootView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var context

    /// DEBUG builds can bypass the paywall so development never depends on a working
    /// StoreKit configuration. The flag doesn't exist in release builds.
    private var hasAccess: Bool {
        #if DEBUG
        if settings.debugUnlocked { return true }
        #endif
        return subscriptions.isSubscribed
    }

    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                OnboardingView { goalDays in
                    WeeklyGoal.setGoal(goalDays, in: context)
                    try? context.save()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        settings.hasCompletedOnboarding = true
                    }
                }
            } else if hasAccess {
                MainTabView()
            } else {
                switch subscriptions.status {
                case .loading:
                    // Never show a paywall while entitlements are still being checked —
                    // a paying subscriber would get a paywall flash on every cold launch.
                    LaunchView()
                case .expired:
                    ResubscribeView()
                case .never, .subscribed:
                    PaywallView()
                }
            }
        }
        .preferredColorScheme(settings.appearance.colorScheme)
        .tint(Theme.accent)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            CalendarTabView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            RecordsTabView()
                .tabItem { Label("Records", systemImage: "trophy.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

/// Shown for the fraction of a second it takes to check entitlements on launch.
struct LaunchView: View {
    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(Theme.accentGradient)
                ProgressView()
                    .tint(Theme.accent)
            }
        }
        .accessibilityLabel("Loading")
    }
}

import SwiftData
import SwiftUI

/// Decides what the user sees: onboarding, or the app.
struct RootView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

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
            } else {
                MainTabView()
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

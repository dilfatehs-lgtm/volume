import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {

    @Environment(AppSettings.self) private var settings
    @Environment(SubscriptionManager.self) private var subscriptions
    @Environment(\.modelContext) private var context
    @Query private var goals: [WeeklyGoal]

    @State private var goalDays = StreakCalculator.defaultWeeklyGoal
    @State private var didLoadGoal = false
    @State private var managingSubscription = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            List {
                Section("Appearance") {
                    ForEach(AppearanceMode.allCases) { mode in
                        choiceRow(title: mode.displayName,
                                  icon: mode.iconName,
                                  detail: mode == .automatic ? "Follows your device" : nil,
                                  isSelected: settings.appearance == mode) {
                            settings.appearance = mode
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        WeeklyGoalPicker(days: $goalDays)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Weekly goal")
                } footer: {
                    Text("Applies from this week onward. Past weeks keep the goal they were judged by, so changing this can't rewrite your streak.")
                }

                Section("Units") {
                    ForEach(WeightUnit.allCases) { unit in
                        choiceRow(title: unit.displayName,
                                  icon: unit == .pounds ? "scalemass" : "scalemass.fill",
                                  detail: nil,
                                  isSelected: settings.unit == unit) {
                            settings.unit = unit
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(subscriptionStatusText)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                    .accessibilityElement(children: .combine)

                    Button("Manage subscription") { managingSubscription = true }
                        .frame(minHeight: Theme.minTapTarget)

                    Button("Restore purchases") {
                        Task { await subscriptions.restore() }
                    }
                    .frame(minHeight: Theme.minTapTarget)
                } header: {
                    Text("Subscription")
                } footer: {
                    if let error = subscriptions.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section {
                    Link("Terms of Use", destination: LegalLinks.terms)
                        .frame(minHeight: Theme.minTapTarget)
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                        .frame(minHeight: Theme.minTapTarget)
                } footer: {
                    Text(VolumeStore.isCloudKitEnabled
                         ? "Your workouts sync through your iCloud account."
                         : "Syncing is off — your workouts are saved on this device only.")
                }

                #if DEBUG
                developerSection
                #endif
            }
            .navigationTitle("Settings")
            .manageSubscriptionsSheet(isPresented: $managingSubscription)
            .onAppear(perform: loadGoalIfNeeded)
            .onChange(of: goalDays) { _, newValue in
                guard didLoadGoal else { return }
                WeeklyGoal.setGoal(newValue, in: context)
                try? context.save()
            }
        }
    }

    // MARK: - Rows

    private func choiceRow(title: String,
                           icon: String,
                           detail: String?,
                           isSelected: Bool,
                           action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selectionChanged()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title).foregroundStyle(.primary)
                    if let detail {
                        Text(detail).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Theme.accent)
                }
            }
            .frame(minHeight: Theme.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var subscriptionStatusText: String {
        switch subscriptions.status {
        case .loading: "Checking…"
        case .subscribed: "Active"
        case .expired: "Expired"
        case .never: "Not subscribed"
        }
    }

    private func loadGoalIfNeeded() {
        guard !didLoadGoal else { return }
        goalDays = StreakCalculator.currentGoal(goals: goals)
        didLoadGoal = true
    }

    // MARK: - Developer

    #if DEBUG
    @ViewBuilder
    private var developerSection: some View {
        @Bindable var settings = settings

        Section {
            Toggle("Unlock without subscribing", isOn: $settings.debugUnlocked)
                .frame(minHeight: Theme.minTapTarget)

            Button("Load 10 weeks of sample data") {
                SampleData.populate(in: context, unit: settings.unit)
            }
            .frame(minHeight: Theme.minTapTarget)

            Button("Replay onboarding") {
                settings.hasCompletedOnboarding = false
            }
            .frame(minHeight: Theme.minTapTarget)

            Button("Erase all data", role: .destructive) {
                SampleData.clearAll(in: context)
                ExerciseLibrary.seed(in: context)
            }
            .frame(minHeight: Theme.minTapTarget)
        } header: {
            Text("Developer")
        } footer: {
            Text("DEBUG builds only. None of this is compiled into a release build.")
        }
    }
    #endif
}

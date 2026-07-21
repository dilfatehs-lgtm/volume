import SwiftData
import StoreKit
import SwiftUI

/// Shown when a subscription has lapsed.
///
/// The first thing it says is that nothing was deleted, because that's the first thing a
/// lapsed user worries about. Their workouts are still in the store, still syncing —
/// only the UI is gated.
struct ResubscribeView: View {

    @Environment(SubscriptionManager.self) private var subscriptions
    @Query private var sessions: [WorkoutSession]

    @State private var selectedID = SubscriptionManager.annualID

    private var completedCount: Int {
        sessions.filter(\.isCompleted).count
    }

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(Theme.accentGradient)

                        Text("Your subscription ended")
                            .font(Theme.label(30, weight: .black))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.accent)
                        Text(completedCount > 0
                             ? "All \(completedCount) of your workouts are safe."
                             : "Everything you logged is safe.")
                            .font(Theme.label(19, weight: .heavy))
                            .multilineTextAlignment(.center)
                        Text("Nothing has been deleted. Resubscribe and it's all exactly where you left it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .cardBackground()
                    .accessibilityElement(children: .combine)

                    PlanPicker(selectedID: $selectedID)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 32)
                .padding(.bottom, 12)
            }
            .safeAreaInset(edge: .bottom) {
                PurchaseFooter(selectedID: selectedID, trialAvailable: false)
            }
        }
    }
}

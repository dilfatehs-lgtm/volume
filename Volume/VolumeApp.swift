import SwiftData
import SwiftUI

@main
struct VolumeApp: App {

    @State private var settings = AppSettings.shared
    @State private var subscriptions = SubscriptionManager()
    @Environment(\.scenePhase) private var scenePhase

    private let container = VolumeStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(subscriptions)
                .task {
                    VolumeStore.prepare(container)
                }
                .onChange(of: scenePhase) { _, phase in
                    // A subscription can expire — and a failed product load can become
                    // retryable — while the app is backgrounded. Transaction.updates
                    // doesn't cover either, so re-check on every return to foreground.
                    guard phase == .active else { return }
                    Task { await subscriptions.refreshOnForeground() }
                }
        }
        .modelContainer(container)
    }
}

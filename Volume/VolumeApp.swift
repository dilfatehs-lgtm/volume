import SwiftData
import SwiftUI

@main
struct VolumeApp: App {

    @State private var settings = AppSettings.shared
    @State private var subscriptions = SubscriptionManager()

    private let container = VolumeStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(subscriptions)
                .task {
                    VolumeStore.prepare(container)
                }
        }
        .modelContainer(container)
    }
}

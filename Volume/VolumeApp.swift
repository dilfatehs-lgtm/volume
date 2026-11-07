import SwiftData
import SwiftUI

@main
struct VolumeApp: App {

    @State private var settings = AppSettings.shared

    private let container = VolumeStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .task {
                    VolumeStore.prepare(container)
                }
        }
        .modelContainer(container)
    }
}

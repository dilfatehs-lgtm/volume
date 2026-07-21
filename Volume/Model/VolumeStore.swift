import Foundation
import OSLog
import SwiftData

/// Builds the app's `ModelContainer`.
///
/// CloudKit when it's actually usable, then local-only, then in-memory.
///
/// The entitlement check up front is load-bearing, not belt-and-braces. `ModelContainer`
/// happily accepts a `.private` CloudKit configuration whether or not the process is
/// entitled to use CloudKit — it doesn't throw, so a `try/catch` fallback never fires.
/// CloudKit then discovers the missing entitlement asynchronously during mirroring setup
/// and **terminates the process**. That's an unconditional launch crash on any build
/// without a signing team, which is exactly how this project ships until a team is set.
enum VolumeStore {

    static let cloudKitContainerID = "iCloud.com.volume.app"

    private static let log = Logger(subsystem: "com.volume.app", category: "store")

    /// Whether this build can safely use CloudKit.
    ///
    /// **Device builds: always true.** iOS requires them to be signed, so the entitlement
    /// in `Volume.entitlements` is always applied and CloudKit works.
    ///
    /// **Simulator builds: false by default.** This project ships with
    /// `CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO` so it builds and runs with no
    /// development team configured — which also means no entitlements are applied, and
    /// CloudKit kills the process when it finds that out.
    ///
    /// To exercise sync in the simulator: set your team, delete that build setting, and
    /// add `VOLUME_CLOUDKIT_IN_SIMULATOR` to *Active Compilation Conditions*. There is
    /// deliberately no runtime entitlement check here — iOS has no public API to read
    /// your own entitlements, and every workaround (provisioning-profile sniffing,
    /// Mach-O parsing) is wrong for App Store builds.
    static var canUseCloudKit: Bool {
        #if targetEnvironment(simulator) && !VOLUME_CLOUDKIT_IN_SIMULATOR
        return false
        #else
        return true
        #endif
    }

    static let schema = Schema([
        Exercise.self,
        WorkoutTemplate.self,
        WorkoutSession.self,
        ExerciseEntry.self,
        SetEntry.self,
        WeeklyGoal.self,
    ])

    /// Whether the live container ended up syncing. Surfaced in Settings so the user
    /// isn't left wondering why their other device looks different.
    private(set) static var isCloudKitEnabled = false

    static func makeContainer() -> ModelContainer {
        if canUseCloudKit {
            do {
                let configuration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private(cloudKitContainerID)
                )
                let container = try ModelContainer(for: schema, configurations: [configuration])
                isCloudKitEnabled = true
                log.info("Opened CloudKit-backed store (\(cloudKitContainerID, privacy: .public)).")
                return container
            } catch {
                log.warning("""
                    CloudKit store unavailable (\(error.localizedDescription, privacy: .public)). \
                    Falling back to a local store — data is kept, it just won't sync.
                    """)
            }
        } else {
            log.info("""
                Simulator build without entitlements — using a local store. \
                Workouts are saved and everything works; they just won't sync between devices. \
                See the README for enabling iCloud sync.
                """)
        }

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            isCloudKitEnabled = false
            return container
        } catch {
            log.error("Local store failed (\(error.localizedDescription, privacy: .public)).")
        }

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            isCloudKitEnabled = false
            return container
        } catch {
            fatalError("Could not open any persistent store: \(error)")
        }
    }

    /// One-time setup run on launch, once the container exists.
    @MainActor
    static func prepare(_ container: ModelContainer) {
        let context = container.mainContext
        ExerciseLibrary.seed(in: context)
        ensureWeeklyGoalExists(in: context)
        try? context.save()
        #if DEBUG
        applyDebugLaunchArguments(in: context)
        #endif
    }

    #if DEBUG
    /// Launch arguments for jumping straight to a given state — handy for screenshots,
    /// demos and manual testing without tapping through onboarding every time.
    ///
    ///   -VolumeResetData        wipe everything and re-seed the exercise library
    ///   -VolumeSampleData       load ten weeks of history
    ///   -VolumeSkipOnboarding   mark onboarding complete
    ///   -VolumeUnlock           bypass the paywall
    ///
    /// Set them in Xcode under Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Arguments.
    @MainActor
    private static func applyDebugLaunchArguments(in context: ModelContext) {
        let arguments = Set(ProcessInfo.processInfo.arguments)
        guard !arguments.isDisjoint(with: [
            "-VolumeResetData", "-VolumeSampleData", "-VolumeSkipOnboarding", "-VolumeUnlock",
        ]) else { return }

        // Reset runs first so the flags below can layer on top of a clean slate.
        if arguments.contains("-VolumeResetData") {
            SampleData.clearAll(in: context)
            ExerciseLibrary.seed(in: context)
            ensureWeeklyGoalExists(in: context)
            AppSettings.shared.hasCompletedOnboarding = false
            AppSettings.shared.debugUnlocked = false
        }
        if arguments.contains("-VolumeSampleData") {
            SampleData.populate(in: context, unit: AppSettings.shared.unit)
        }
        if arguments.contains("-VolumeSkipOnboarding") {
            AppSettings.shared.hasCompletedOnboarding = true
        }
        if arguments.contains("-VolumeUnlock") {
            AppSettings.shared.debugUnlocked = true
        }
        try? context.save()
    }
    #endif

    /// Guarantees there is always a goal in force, even for users who skipped onboarding.
    @MainActor
    private static func ensureWeeklyGoalExists(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<WeeklyGoal>())) ?? []
        guard existing.isEmpty else { return }
        // Backdated so the very first week is judged by it too.
        context.insert(WeeklyGoal(daysPerWeek: StreakCalculator.defaultWeeklyGoal,
                                  effectiveFrom: .distantPast))
    }

    /// In-memory container for SwiftUI previews, pre-populated with sample data.
    @MainActor
    static func previewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema,
                                               isStoredInMemoryOnly: true,
                                               cloudKitDatabase: .none)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        ExerciseLibrary.seed(in: container.mainContext)
        #if DEBUG
        SampleData.populate(in: container.mainContext)
        #endif
        return container
    }
}

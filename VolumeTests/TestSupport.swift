import Foundation
import SwiftData
import XCTest
@testable import Volume

/// Shared fixtures. Everything uses a fixed UTC Gregorian calendar with Sunday as the
/// first weekday, so week-boundary assertions don't change with the machine's locale.
@MainActor
class VolumeTestCase: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    /// Wednesday, 22 July 2026. The containing week starts Sunday 19 July.
    let now = VolumeTestCase.date(2026, 7, 22)

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    var calendar: Calendar { Self.calendar }

    override func setUp() async throws {
        try await super.setUp()
        let configuration = ModelConfiguration(schema: VolumeStore.schema,
                                               isStoredInMemoryOnly: true,
                                               cloudKitDatabase: .none)
        container = try ModelContainer(for: VolumeStore.schema, configurations: [configuration])
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - Builders

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 18) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return calendar.date(from: components)!
    }

    func makeTemplate(_ name: String) -> WorkoutTemplate {
        let template = WorkoutTemplate(name: name)
        context.insert(template)
        return template
    }

    func makeExercise(_ name: String, bodyweight: Bool = false) -> Exercise {
        let exercise = Exercise(name: name, slug: name.lowercased(), isBodyweight: bodyweight)
        context.insert(exercise)
        return exercise
    }

    /// A completed session containing one exercise with the given sets.
    @discardableResult
    func makeSession(_ template: WorkoutTemplate,
                     on date: Date,
                     sets: [(reps: Int, weight: Double?)],
                     unit: WeightUnit = .pounds,
                     completed: Bool = true,
                     exercise: Exercise? = nil) -> WorkoutSession {
        let session = WorkoutSession(date: date, template: template, isCompleted: completed)
        context.insert(session)

        let entry = ExerciseEntry(order: 0, exercise: exercise ?? makeExercise("Bench"))
        entry.session = session
        context.insert(entry)

        for (index, spec) in sets.enumerated() {
            let set = SetEntry(order: index,
                               reps: spec.reps,
                               weightValue: spec.weight,
                               unit: unit,
                               loggedAt: date)
            set.entry = entry
            context.insert(set)
        }
        return session
    }

    /// A session whose total score is exactly `score` (one set of `score` bodyweight reps).
    @discardableResult
    func makeSession(_ template: WorkoutTemplate, on date: Date, score: Int) -> WorkoutSession {
        makeSession(template, on: date, sets: [(reps: score, weight: nil)])
    }

    func allSessions() -> [WorkoutSession] {
        (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
    }
}

import Foundation
import SwiftData

struct ScorePoint: Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let score: Double
}

/// Everything the Records tab shows about one workout.
///
/// Personal bests and PR counts are log facts — the max of what you logged, and a count of
/// how often you beat yourself. Same category as "last workout's score" on Home. No trends,
/// no projections, no commentary.
struct TemplateRecord: Identifiable {
    let id: String
    let name: String
    /// `nil` when the template was deleted; its sessions still have records worth showing.
    let template: WorkoutTemplate?
    let bestScore: Double
    let bestDate: Date
    let lastScore: Double
    let lastDate: Date
    let personalRecords: Int
    let sessionCount: Int
    /// Chronological, for the sparkline and the detail chart.
    let points: [ScorePoint]

    var isAtBest: Bool { lastScore >= bestScore }
}

enum WorkoutRecords {

    /// One entry per distinct workout, most recently performed first.
    ///
    /// Grouped by `comparisonKey` — the same identity used for the score to beat and both
    /// streaks — so a renamed template keeps its history, and sessions orphaned by a
    /// deleted template still group together instead of scattering.
    static func all(sessions: [WorkoutSession], unit: WeightUnit) -> [TemplateRecord] {
        let completed = sessions.filter(\.isCompleted).sorted { $0.date < $1.date }
        guard !completed.isEmpty else { return [] }

        // Reuse the single definition of "beat" rather than recomputing it here.
        var recordCounts: [SessionComparisonKey: Int] = [:]
        for result in StreakCalculator.outcomes(sessions: sessions, unit: unit)
        where result.outcome == .beat {
            recordCounts[result.session.comparisonKey, default: 0] += 1
        }

        var grouped: [SessionComparisonKey: [WorkoutSession]] = [:]
        for session in completed {
            grouped[session.comparisonKey, default: []].append(session)
        }

        return grouped.compactMap { key, group -> TemplateRecord? in
            guard let latest = group.last else { return nil }

            let points = group.map {
                ScorePoint(id: $0.persistentModelID,
                           date: $0.date,
                           score: VolumeScore.score(for: $0, in: unit))
            }
            guard let best = points.max(by: { $0.score < $1.score }),
                  let last = points.last else { return nil }

            return TemplateRecord(id: identifier(for: key),
                                  name: latest.displayName,
                                  template: latest.template,
                                  bestScore: best.score,
                                  bestDate: best.date,
                                  lastScore: last.score,
                                  lastDate: last.date,
                                  personalRecords: recordCounts[key] ?? 0,
                                  sessionCount: group.count,
                                  points: points)
        }
        .sorted { $0.lastDate > $1.lastDate }
    }

    private static func identifier(for key: SessionComparisonKey) -> String {
        switch key {
        case .model(let id): "t:\(String(describing: id))"
        case .name(let name): "n:\(name)"
        }
    }
}

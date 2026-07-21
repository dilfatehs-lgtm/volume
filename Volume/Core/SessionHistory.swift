import Foundation

/// Look-ups that answer "what am I being compared against?".
///
/// Every comparison in Volume is like-for-like: a session is only ever measured against
/// an earlier session of the *same template*. That is the whole reason the app never
/// needs to know what a "split" is — the template a user named ("Pull", "Upper",
/// "Maria's Tuesday Workout") already carries that meaning.
enum SessionHistory {

    /// The most recent completed session of the same template, strictly before `session`.
    /// This is the Score to Beat. `nil` means it's the first time doing this workout.
    static func previousSession(for session: WorkoutSession,
                                among sessions: [WorkoutSession]) -> WorkoutSession? {
        let key = session.comparisonKey
        return sessions
            .filter { candidate in
                candidate.isCompleted
                    && candidate.persistentModelID != session.persistentModelID
                    && candidate.comparisonKey == key
                    && candidate.date < session.date
            }
            .max { $0.date < $1.date }
    }

    /// The most recent completed session of a template — used on Home so each template
    /// card can show the target you're about to chase before you commit to it.
    static func lastCompletedSession(for template: WorkoutTemplate,
                                     among sessions: [WorkoutSession]) -> WorkoutSession? {
        sessions
            .filter { $0.isCompleted && $0.comparisonKey == .model(template.persistentModelID) }
            .max { $0.date < $1.date }
    }

    /// Whether a completed session beat what it was measured against.
    /// `nil` when there was nothing to beat — the first session of a template is
    /// neither a win nor a loss.
    static func didBeatTarget(_ session: WorkoutSession,
                              among sessions: [WorkoutSession],
                              unit: WeightUnit) -> Bool? {
        guard let previous = previousSession(for: session, among: sessions) else { return nil }
        return VolumeScore.score(for: session, in: unit) > VolumeScore.score(for: previous, in: unit)
    }
}

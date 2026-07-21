import Foundation

struct WeeklyProgress: Equatable {
    var daysCompleted: Int
    var goal: Int

    var isMet: Bool { daysCompleted >= goal }
    var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(Double(daysCompleted) / Double(goal), 1)
    }
}

/// Both streaks in the app.
///
/// They measure two different things on purpose: the record streak asks *are you getting
/// stronger*, the weekly streak asks *are you showing up as often as you said you would*.
enum StreakCalculator {

    static let defaultWeeklyGoal = 3
    static let goalRange = 1...7

    // MARK: - Record streak

    enum RecordOutcome {
        case beat
        case missed
        /// First-ever session of a template. Nothing was there to beat, so this neither
        /// extends nor resets the streak — trying a new workout is never punished.
        case neutral
    }

    struct SessionOutcome {
        let session: WorkoutSession
        let outcome: RecordOutcome
    }

    /// Every completed session in date order, each judged against the previous session of
    /// its own template.
    ///
    /// The single source of truth for what "beat" means. The current streak, the best-ever
    /// streak and each workout's PR count all derive from this one list, and the rule is
    /// deliberately identical to the celebration trigger in `ActiveWorkoutModel` — there is
    /// no state in which the confetti fires but the numbers disagree.
    static func outcomes(sessions: [WorkoutSession], unit: WeightUnit) -> [SessionOutcome] {
        let completed = sessions.filter(\.isCompleted).sorted { $0.date < $1.date }

        var lastScoreByTemplate: [SessionComparisonKey: Double] = [:]
        var results: [SessionOutcome] = []

        for session in completed {
            let key = session.comparisonKey
            let score = VolumeScore.score(for: session, in: unit)
            if let previous = lastScoreByTemplate[key] {
                results.append(SessionOutcome(session: session,
                                              outcome: score > previous ? .beat : .missed))
            } else {
                results.append(SessionOutcome(session: session, outcome: .neutral))
            }
            lastScoreByTemplate[key] = score
        }
        return results
    }

    /// Consecutive completed sessions, most recent backwards, that beat their score to beat.
    static func recordStreak(sessions: [WorkoutSession], unit: WeightUnit) -> Int {
        var streak = 0
        for result in outcomes(sessions: sessions, unit: unit).reversed() {
            switch result.outcome {
            case .neutral: continue
            case .beat: streak += 1
            case .missed: return streak
            }
        }
        return streak
    }

    /// The longest run of records the user has ever put together.
    ///
    /// Uses the same neutral-skipping rule as the current streak, so a run isn't broken
    /// just because a new workout was tried partway through it.
    static func bestRecordStreak(sessions: [WorkoutSession], unit: WeightUnit) -> Int {
        var best = 0
        var running = 0
        for result in outcomes(sessions: sessions, unit: unit) {
            switch result.outcome {
            case .neutral: continue
            case .beat:
                running += 1
                best = max(best, running)
            case .missed:
                running = 0
            }
        }
        return best
    }

    // MARK: - Weekly goal streak

    /// Start of the week containing `date`, honouring the device locale's first weekday
    /// — Sunday in the US, Monday across most of Europe. No setting, no jargon.
    static func weekStart(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    /// The goal that was in force during the week starting `weekStart`.
    ///
    /// Goal changes are forward-only: each change appends a dated `WeeklyGoal` rather
    /// than overwriting one, so past weeks keep being judged by the goal that applied at
    /// the time. Dropping 5→2 can't retroactively gift a streak, and raising 2→7 can't
    /// wipe one that was genuinely earned.
    static func goal(forWeekStarting weekStart: Date, goals: [WeeklyGoal]) -> Int {
        let inForce = goals
            .filter { $0.effectiveFrom <= weekStart }
            .max { $0.effectiveFrom < $1.effectiveFrom }
        if let inForce { return inForce.daysPerWeek }
        // Weeks predating any recorded goal (imported or sample data) fall back to the
        // earliest goal the user ever set, then to the default.
        let earliest = goals.min { $0.effectiveFrom < $1.effectiveFrom }
        return earliest?.daysPerWeek ?? defaultWeeklyGoal
    }

    static func currentGoal(goals: [WeeklyGoal],
                            calendar: Calendar = .current,
                            now: Date = Date()) -> Int {
        goal(forWeekStarting: weekStart(for: now, calendar: calendar), goals: goals)
    }

    /// Distinct calendar days with at least one completed session, bucketed by week.
    ///
    /// Days, not sessions: two workouts on the same Saturday count once toward a 4-day
    /// goal. Counting sessions would make the goal trivially gameable by cramming.
    private static func workoutDaysByWeek(_ sessions: [WorkoutSession],
                                          calendar: Calendar) -> [Date: Set<Date>] {
        var result: [Date: Set<Date>] = [:]
        for session in sessions where session.isCompleted {
            let week = weekStart(for: session.date, calendar: calendar)
            result[week, default: []].insert(calendar.startOfDay(for: session.date))
        }
        return result
    }

    static func currentWeekProgress(sessions: [WorkoutSession],
                                    goals: [WeeklyGoal],
                                    calendar: Calendar = .current,
                                    now: Date = Date()) -> WeeklyProgress {
        let week = weekStart(for: now, calendar: calendar)
        let days = workoutDaysByWeek(sessions, calendar: calendar)[week]?.count ?? 0
        return WeeklyProgress(daysCompleted: days,
                              goal: goal(forWeekStarting: week, goals: goals))
    }

    struct WeekResult {
        let weekStart: Date
        let daysCompleted: Int
        let goal: Int
        var isMet: Bool { daysCompleted >= goal }
    }

    /// Every week from the user's first workout up to and including the current one, each
    /// judged against the goal that was in force at the time.
    ///
    /// Weeks with no workouts at all are included as misses — that's what breaks a streak.
    /// Shared by `weeklyStreak` and `bestWeeklyStreak` so the two can never disagree.
    static func weekResults(sessions: [WorkoutSession],
                            goals: [WeeklyGoal],
                            calendar: Calendar = .current,
                            now: Date = Date()) -> [WeekResult] {
        let byWeek = workoutDaysByWeek(sessions, calendar: calendar)
        guard let earliestWeek = byWeek.keys.min() else { return [] }

        let currentWeek = weekStart(for: now, calendar: calendar)
        var results: [WeekResult] = []
        var week = earliestWeek

        while week <= currentWeek {
            results.append(WeekResult(weekStart: week,
                                      daysCompleted: byWeek[week]?.count ?? 0,
                                      goal: goal(forWeekStarting: week, goals: goals)))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: week) else { break }
            week = next
        }
        return results
    }

    /// Consecutive weeks in which the user hit their own goal.
    ///
    /// The in-progress week can only ever help: if it's already met it counts, and if it
    /// isn't it's simply skipped rather than treated as a failure. Without that, every
    /// user's streak would read as broken every Monday morning.
    static func weeklyStreak(sessions: [WorkoutSession],
                             goals: [WeeklyGoal],
                             calendar: Calendar = .current,
                             now: Date = Date()) -> Int {
        var results = weekResults(sessions: sessions, goals: goals, calendar: calendar, now: now)
        guard !results.isEmpty else { return 0 }

        var streak = 0
        // The current week is the only one allowed to be incomplete without breaking
        // anything — drop it unjudged if it hasn't been met yet.
        if let current = results.last {
            if current.isMet { streak += 1 }
            results.removeLast()
        }

        for result in results.reversed() {
            guard result.isMet else { break }
            streak += 1
        }
        return streak
    }

    /// The longest run of goal-hitting weeks the user has ever put together.
    ///
    /// The current week is only counted once it's actually met, for the same reason it
    /// can't break the current streak: it isn't over yet.
    static func bestWeeklyStreak(sessions: [WorkoutSession],
                                 goals: [WeeklyGoal],
                                 calendar: Calendar = .current,
                                 now: Date = Date()) -> Int {
        var results = weekResults(sessions: sessions, goals: goals, calendar: calendar, now: now)
        if let current = results.last, !current.isMet {
            results.removeLast()
        }

        var best = 0
        var running = 0
        for result in results {
            if result.isMet {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }
        return best
    }
}

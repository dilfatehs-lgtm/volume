import Charts
import SwiftData
import SwiftUI

/// The trophy cabinet: streaks first, personal bests per workout, and the line one tap
/// away for anyone who wants it.
///
/// This replaced a tab that opened with a bare chart. The chart is still here — it's the
/// only thing that shows a lifter eight months in that they went 9,200 to 13,600 — but it
/// no longer leads, because a spreadsheet is a poor front door for an app about beating
/// your own number.
struct RecordsTabView: View {

    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkoutSession.date) private var sessions: [WorkoutSession]
    @Query private var goals: [WeeklyGoal]

    private var unit: WeightUnit { settings.unit }

    private var records: [TemplateRecord] {
        WorkoutRecords.all(sessions: sessions, unit: unit)
    }

    private var currentStreak: Int {
        StreakCalculator.recordStreak(sessions: sessions, unit: unit)
    }

    private var bestStreak: Int {
        StreakCalculator.bestRecordStreak(sessions: sessions, unit: unit)
    }

    private var weekProgress: WeeklyProgress {
        StreakCalculator.currentWeekProgress(sessions: sessions, goals: goals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if records.isEmpty {
                        EmptyStateView(icon: "trophy.fill",
                                       title: "No records yet",
                                       message: "Finish a workout, then beat it next time. Your bests land here.")
                            .cardBackground()
                    } else {
                        recordStreakCard
                        weeklyCard
                        workoutList
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .background(Theme.surface)
            .navigationTitle("Records")
        }
    }

    // MARK: - Streaks

    private var recordStreakCard: some View {
        VStack(spacing: 4) {
            Text(currentStreak > 0 ? "🔥 \(currentStreak)" : "🔥")
                .font(Theme.numeral(currentStreak > 0 ? 68 : 44))
                .monospacedDigit()
                .foregroundStyle(currentStreak > 0 ? AnyShapeStyle(Theme.accentGradient)
                                                   : AnyShapeStyle(Color.secondary))
                .contentTransition(.numericText(value: Double(currentStreak)))
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: currentStreak)

            Text(currentStreak == 1 ? "RECORD IN A ROW" : "RECORDS IN A ROW")
                .font(Theme.label(13, weight: .heavy))
                .tracking(1.3)
                .foregroundStyle(.secondary)

            if bestStreak > 0 {
                Text(currentStreak >= bestStreak && currentStreak > 0
                     ? "your best run yet"
                     : "best ever \(bestStreak)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Record streak")
        .accessibilityValue("\(currentStreak) in a row. Best ever \(bestStreak).")
    }

    private var weeklyCard: some View {
        let streak = StreakCalculator.weeklyStreak(sessions: sessions, goals: goals)
        let best = StreakCalculator.bestWeeklyStreak(sessions: sessions, goals: goals)

        return HStack(spacing: 14) {
            WeeklyGoalRing(progress: weekProgress)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(weekProgress.daysCompleted) of \(weekProgress.goal) this week")
                    .font(Theme.label(17, weight: .heavy))
                Text(streak > 0 ? "\(streak) week streak · best \(best)"
                                : "Hit your goal to start a week streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly goal")
        .accessibilityValue("\(weekProgress.daysCompleted) of \(weekProgress.goal) days this week. \(streak) week streak, best \(best).")
    }

    // MARK: - Per workout

    private var workoutList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Your workouts")

            ForEach(records) { record in
                NavigationLink {
                    TemplateProgressView(record: record)
                } label: {
                    workoutRow(record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func workoutRow(_ record: TemplateRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.name)
                    .font(Theme.label(18, weight: .heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("Best \(VolumeScore.format(record.bestScore))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if record.personalRecords > 0 {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("\(record.personalRecords) PR\(record.personalRecords == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            Spacer(minLength: 6)

            if record.points.count >= 2 {
                Sparkline(points: record.points)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(minHeight: Theme.minTapTarget + 18)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(record.name)
        .accessibilityValue("Best \(VolumeScore.format(record.bestScore)), \(record.personalRecords) personal records, \(record.sessionCount) workouts logged")
        .accessibilityHint("Opens this workout's scores over time")
    }
}

/// Tiny inline trend, purely decorative — the readable version is one tap away.
struct Sparkline: View {
    let points: [ScorePoint]

    var body: some View {
        Chart(points) { point in
            LineMark(x: .value("Date", point.date), y: .value("Score", point.score))
                .foregroundStyle(Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(width: 66, height: 30)
        .accessibilityHidden(true)
    }
}

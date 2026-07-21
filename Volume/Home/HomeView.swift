import SwiftData
import SwiftUI

struct HomeView: View {

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \WorkoutTemplate.createdAt) private var templates: [WorkoutTemplate]
    @Query private var goals: [WeeklyGoal]

    @State private var showingTemplatePicker = false
    @State private var activeSession: WorkoutSession?

    private var unit: WeightUnit { settings.unit }

    /// A workout left open — the app was backgrounded or closed mid-session.
    private var inProgressSession: WorkoutSession? {
        sessions.first { !$0.isCompleted }
    }

    private var lastCompleted: WorkoutSession? {
        sessions.first(where: \.isCompleted)
    }

    private var recordStreak: Int {
        StreakCalculator.recordStreak(sessions: sessions, unit: unit)
    }

    private var weekProgress: WeeklyProgress {
        StreakCalculator.currentWeekProgress(sessions: sessions, goals: goals)
    }

    private var weeklyStreak: Int {
        StreakCalculator.weeklyStreak(sessions: sessions, goals: goals)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    startButton
                        .padding(.top, 4)

                    recordStreakCard
                    weeklyGoalCard

                    if let lastCompleted {
                        lastWorkoutRow(lastCompleted)
                    }

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .background(Theme.surface)
            .navigationTitle("Volume")
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerSheet(templates: templates,
                                    sessions: sessions,
                                    unit: unit) { template, date in
                    startWorkout(with: template, on: date)
                }
            }
            .fullScreenCover(item: $activeSession) { session in
                ActiveWorkoutView(session: session, context: context, unit: unit)
            }
        }
    }

    // MARK: - Start

    private var startButton: some View {
        Button {
            Haptics.tap()
            if let inProgressSession {
                activeSession = inProgressSession
            } else {
                showingTemplatePicker = true
            }
        } label: {
            VStack(spacing: 10) {
                Image(systemName: inProgressSession == nil ? "figure.strengthtraining.traditional" : "arrow.clockwise")
                    .font(.system(size: 44, weight: .black))
                Text(inProgressSession == nil ? "START WORKOUT" : "RESUME WORKOUT")
                    .font(Theme.label(27, weight: .black))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let inProgressSession {
                    Text(inProgressSession.displayName)
                        .font(Theme.label(15, weight: .semibold))
                        .opacity(0.9)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Theme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(inProgressSession == nil
                            ? "Start workout"
                            : "Resume \(inProgressSession?.displayName ?? "workout")")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Streaks

    private var recordStreakCard: some View {
        VStack(spacing: 4) {
            Text(recordStreak > 0 ? "🔥 \(recordStreak)" : "🔥")
                .font(Theme.numeral(recordStreak > 0 ? 68 : 44))
                .monospacedDigit()
                .foregroundStyle(recordStreak > 0 ? AnyShapeStyle(Theme.accentGradient)
                                                  : AnyShapeStyle(Color.secondary))
                .contentTransition(.numericText(value: Double(recordStreak)))
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: recordStreak)

            Text(recordStreak == 1 ? "RECORD IN A ROW" : "RECORDS IN A ROW")
                .font(Theme.label(13, weight: .heavy))
                .tracking(1.3)
                .foregroundStyle(.secondary)

            if recordStreak == 0 {
                Text("Beat a workout's last score to start one.")
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
        .accessibilityValue(recordStreak == 0
                            ? "None yet. Beat a workout's last score to start one."
                            : "\(recordStreak) \(recordStreak == 1 ? "record" : "records") in a row")
    }

    private var weeklyGoalCard: some View {
        HStack(spacing: 14) {
            WeeklyGoalRing(progress: weekProgress)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(weekProgress.daysCompleted) of \(weekProgress.goal) this week")
                    .font(Theme.label(17, weight: .heavy))
                Text(weeklyStreak > 0
                     ? "\(weeklyStreak) week \(weeklyStreak == 1 ? "streak" : "streak")"
                     : "Hit your goal to start a week streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if weeklyStreak > 0 {
                Text("\(weeklyStreak)")
                    .font(Theme.numeral(30))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(16)
        .cardBackground()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly goal")
        .accessibilityValue("\(weekProgress.daysCompleted) of \(weekProgress.goal) days this week. \(weeklyStreak > 0 ? "\(weeklyStreak) week streak." : "No week streak yet.")")
    }

    private func lastWorkoutRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Last workout")
                    .font(Theme.label(12, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(session.displayName)
                    .font(Theme.label(17, weight: .bold))
                Text(session.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ScorePill(score: VolumeScore.score(for: session, in: unit), prominent: true)
        }
        .padding(16)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func startWorkout(with template: WorkoutTemplate, on date: Date) {
        // Clamped: a workout in the future would scramble the date ordering that every
        // score-to-beat comparison depends on.
        let session = WorkoutSession(date: min(date, Date()), template: template)
        context.insert(session)
        try? context.save()
        activeSession = session
    }
}

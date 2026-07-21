import SwiftUI

/// What happened, stated plainly.
///
/// Beating your score gets the full celebration. Falling short gets the number and
/// nothing else — no encouragement, no explanation, no suggestion for next time. The app
/// keeps the log; the user draws the conclusions.
struct WorkoutSummaryView: View {

    let summary: WorkoutSummary
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            if summary.didBeatTarget && !reduceMotion {
                ConfettiView(particleCount: 110)
                    .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 22) {
                    headline

                    ScoreDisplay(score: summary.score,
                                 size: 84,
                                 isRecord: summary.didBeatTarget,
                                 caption: "\(summary.templateName) volume")
                        .padding(.vertical, 4)

                    comparison

                    if summary.didBeatTarget && summary.recordStreak > 1 {
                        streakBadge
                    }

                    statsRow

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 32)
            }
            .safeAreaInset(edge: .bottom) {
                Button("Done", action: onDone)
                    .buttonStyle(.big)
                    .padding(.horizontal, Theme.gutter)
                    .padding(.bottom, 8)
            }
        }
        .onAppear {
            UIAccessibility.post(notification: .screenChanged, argument: accessibilitySummary)
        }
    }

    // MARK: - Pieces

    @ViewBuilder
    private var headline: some View {
        if summary.didBeatTarget {
            Text("NEW RECORD 🔥")
                .font(Theme.label(34, weight: .black))
                .foregroundStyle(Theme.accentGradient)
                .multilineTextAlignment(.center)
        } else if summary.previousScore == nil {
            Text("FIRST ONE LOGGED")
                .font(Theme.label(26, weight: .black))
                .tracking(0.5)
                .foregroundStyle(.primary)
        } else {
            Text("WORKOUT SAVED")
                .font(Theme.label(26, weight: .black))
                .tracking(0.5)
                .foregroundStyle(.primary)
        }
    }

    @ViewBuilder
    private var comparison: some View {
        if let previousScore = summary.previousScore, let delta = summary.delta {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(VolumeScore.formatDelta(delta))
                        .font(Theme.label(28, weight: .black))
                        .monospacedDigit()
                        .foregroundStyle(summary.didBeatTarget ? Theme.accent : .secondary)

                    if let percent = summary.percentDelta {
                        Text("(\(percent >= 0 ? "+" : "")\(String(format: "%.0f", percent))%)")
                            .font(Theme.label(18, weight: .heavy))
                            .foregroundStyle(.secondary)
                    }
                }
                Text("vs last \(summary.templateName) — \(VolumeScore.format(previousScore))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .cardBackground()
        } else {
            Text("This is the score to beat next time.")
                .font(Theme.label(16, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(18)
                .frame(maxWidth: .infinity)
                .cardBackground()
        }
    }

    private var streakBadge: some View {
        Text("🔥 \(summary.recordStreak) IN A ROW")
            .font(Theme.label(17, weight: .black))
            .tracking(1.1)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Theme.accentGradient))
            .accessibilityLabel("\(summary.recordStreak) records in a row")
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat(value: "\(summary.exerciseCount)",
                 label: summary.exerciseCount == 1 ? "Exercise" : "Exercises")
            stat(value: "\(summary.totalSets)",
                 label: summary.totalSets == 1 ? "Set" : "Sets")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.numeral(30))
                .monospacedDigit()
            Text(label.uppercased())
                .font(Theme.label(11, weight: .heavy))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }

    private var accessibilitySummary: String {
        var parts = [String]()
        if summary.didBeatTarget {
            parts.append("New record.")
        }
        parts.append("\(summary.templateName) volume \(VolumeScore.format(summary.score)).")
        if let delta = summary.delta {
            parts.append("\(VolumeScore.formatDelta(delta)) versus last time.")
        } else {
            parts.append("This is the score to beat next time.")
        }
        if summary.didBeatTarget && summary.recordStreak > 1 {
            parts.append("\(summary.recordStreak) records in a row.")
        }
        return parts.joined(separator: " ")
    }
}

#Preview("Record") {
    WorkoutSummaryView(summary: WorkoutSummary(templateName: "Push",
                                               score: 14820,
                                               previousScore: 12480,
                                               didBeatTarget: true,
                                               recordStreak: 4,
                                               totalSets: 17,
                                               exerciseCount: 5)) {}
}

#Preview("Short of it") {
    WorkoutSummaryView(summary: WorkoutSummary(templateName: "Legs",
                                               score: 11660,
                                               previousScore: 12480,
                                               didBeatTarget: false,
                                               recordStreak: 0,
                                               totalSets: 15,
                                               exerciseCount: 5)) {}
}

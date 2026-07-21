import Charts
import SwiftData
import SwiftUI

/// Six steps, first launch only.
///
/// The job isn't to list features — it's to teach the loop (log → score → beat it →
/// streak) before asking for money. Each step animates a real component from the app, so
/// onboarding is a preview of the product rather than a description of it.
struct OnboardingView: View {

    var onFinish: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var goalDays = StreakCalculator.defaultWeeklyGoal

    private let lastPage = 5

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                skipBar

                TabView(selection: $page) {
                    welcome.tag(0)
                    logging.tag(1)
                    scoring.tag(2)
                    beating.tag(3)
                    streaking.tag(4)
                    goalStep.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: page)

                dots

                Button(page == lastPage ? "Get Started" : "Next") {
                    Haptics.tap()
                    if page == lastPage {
                        onFinish(goalDays)
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(.big)
                .padding(.horizontal, Theme.gutter)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Chrome

    private var skipBar: some View {
        HStack {
            Spacer()
            if page < lastPage {
                Button("Skip") { onFinish(goalDays) }
                    .font(Theme.label(16, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: Theme.minTapTarget, minHeight: 44)
                    .accessibilityHint("Skips the tour and uses a goal of \(StreakCalculator.defaultWeeklyGoal) days a week")
            }
        }
        .padding(.horizontal, Theme.gutter)
        .frame(height: 44)
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0...lastPage, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AnyShapeStyle(Theme.accentGradient)
                                        : AnyShapeStyle(Theme.hairline))
                    .frame(width: index == page ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: page)
            }
        }
        .padding(.vertical, 16)
        .accessibilityHidden(true)
    }

    // MARK: - Steps

    private var welcome: some View {
        OnboardingStep(title: "Welcome to Volume",
                       message: "One number for how much work you did. Beat it next time. That's the whole app.") {
            CountingScoreDemo(target: 12480, isActive: page == 0, reduceMotion: reduceMotion)
        }
    }

    private var logging: some View {
        OnboardingStep(title: "Log your sets and reps",
                       message: "Reps always. Weight when there is one. Nothing else to fill in.") {
            SetRowsDemo(isActive: page == 1, reduceMotion: reduceMotion)
        }
    }

    private var scoring: some View {
        OnboardingStep(title: "Every rep becomes a score",
                       message: "Reps × weight, added up across every set. Bodyweight sets count their reps.") {
            ScoreMathDemo(isActive: page == 2, reduceMotion: reduceMotion)
        }
    }

    private var beating: some View {
        OnboardingStep(title: "Beat your last score",
                       message: "Start a workout and last time's score is already the target. Pass it and you'll know.") {
            RecordDemo(isActive: page == 3, reduceMotion: reduceMotion)
        }
    }

    private var streaking: some View {
        OnboardingStep(title: "Keep the streak alive",
                       message: "Every workout you beat adds to your streak. Watch the line climb.") {
            StreakDemo(isActive: page == 4, reduceMotion: reduceMotion)
        }
    }

    private var goalStep: some View {
        OnboardingStep(title: "How often do you want to train?",
                       message: "Hit this many days in a week to keep your week streak. Change it any time.") {
            WeeklyGoalPicker(days: $goalDays)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: - Step container

private struct OnboardingStep<Demo: View>: View {

    let title: String
    let message: String
    @ViewBuilder var demo: Demo

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                demo
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 220)

                VStack(spacing: 10) {
                    Text(title)
                        .font(Theme.label(30, weight: .black))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Demos

private struct CountingScoreDemo: View {
    let target: Double
    let isActive: Bool
    let reduceMotion: Bool
    @State private var value: Double = 0

    var body: some View {
        ScoreDisplay(score: value, size: 74, caption: "Volume score")
            .onChange(of: isActive, initial: true) { _, active in
                guard active else { return }
                if reduceMotion {
                    value = target
                } else {
                    value = 0
                    withAnimation(.easeOut(duration: 1.1)) { value = target }
                }
            }
    }
}

private struct SetRowsDemo: View {
    let isActive: Bool
    let reduceMotion: Bool
    @State private var shown = 0

    private let rows = [("1", "8 × 135 lb"), ("2", "8 × 135 lb"), ("3", "6 × 145 lb")]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 12) {
                    Text(row.0)
                        .font(Theme.label(14, weight: .heavy))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Theme.surface))
                    Text(row.1)
                        .font(Theme.label(18, weight: .bold))
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .opacity(index < shown ? 1 : 0)
                .offset(y: index < shown ? 0 : 8)
            }
        }
        .padding(.vertical, 12)
        .cardBackground()
        .padding(.horizontal, 8)
        .onChange(of: isActive, initial: true) { _, active in
            guard active else { return }
            guard !reduceMotion else { shown = rows.count; return }
            shown = 0
            for index in 1...rows.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.28) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { shown = index }
                }
            }
        }
    }
}

private struct ScoreMathDemo: View {
    let isActive: Bool
    let reduceMotion: Bool
    @State private var total: Double = 0

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                pill("8 reps")
                Text("×").font(Theme.label(20, weight: .black)).foregroundStyle(.secondary)
                pill("135 lb")
                Text("=").font(Theme.label(20, weight: .black)).foregroundStyle(.secondary)
                pill("1,080")
            }
            Image(systemName: "arrow.down")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.secondary)
            ScoreDisplay(score: total, size: 60, caption: "Session total")
        }
        .onChange(of: isActive, initial: true) { _, active in
            guard active else { return }
            if reduceMotion {
                total = 12480
            } else {
                total = 1080
                withAnimation(.easeOut(duration: 1.2)) { total = 12480 }
            }
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(Theme.label(15, weight: .heavy))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))
            .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    }
}

private struct RecordDemo: View {
    let isActive: Bool
    let reduceMotion: Bool
    @State private var progress: Double = 0.35
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            if showConfetti && !reduceMotion {
                ConfettiView(particleCount: 70)
            }
            ProgressRing(progress: progress, isRecord: progress > 1)
                .frame(width: 190, height: 190)
            VStack(spacing: 2) {
                Text(progress > 1 ? "NEW RECORD" : "OF 12,480")
                    .font(Theme.label(13, weight: .black))
                    .tracking(1.1)
                    .foregroundStyle(progress > 1 ? Theme.accent : .secondary)
                Text(VolumeScore.format(12480 * progress))
                    .font(Theme.numeral(40))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: progress))
            }
        }
        .onChange(of: isActive, initial: true) { _, active in
            guard active else {
                showConfetti = false
                progress = 0.35
                return
            }
            guard !reduceMotion else { progress = 1.14; showConfetti = false; return }
            progress = 0.35
            withAnimation(.easeInOut(duration: 1.5)) { progress = 1.14 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) { showConfetti = true }
        }
    }
}

private struct StreakDemo: View {
    let isActive: Bool
    let reduceMotion: Bool
    @State private var streak = 0

    private let trend: [(week: Int, score: Double)] = [
        (1, 9200), (2, 9800), (3, 10400), (4, 11300), (5, 12480), (6, 13600),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("🔥 \(streak)")
                .font(Theme.numeral(56))
                .monospacedDigit()
                .foregroundStyle(Theme.accentGradient)
                .contentTransition(.numericText(value: Double(streak)))

            Text("RECORDS IN A ROW")
                .font(Theme.label(12, weight: .heavy))
                .tracking(1.3)
                .foregroundStyle(.secondary)

            Chart(trend, id: \.week) { item in
                LineMark(x: .value("Week", item.week), y: .value("Score", item.score))
                    .foregroundStyle(Theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    .interpolationMethod(.monotone)
                AreaMark(x: .value("Week", item.week), y: .value("Score", item.score))
                    .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.3), .clear],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 78)
            .padding(.horizontal, 20)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Record streak of 4, with scores climbing week over week")
        .onChange(of: isActive, initial: true) { _, active in
            guard active else { return }
            guard !reduceMotion else { streak = 4; return }
            streak = 0
            for step in 1...4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.3) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { streak = step }
                }
            }
        }
    }
}

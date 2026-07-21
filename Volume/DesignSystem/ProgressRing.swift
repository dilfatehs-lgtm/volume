import SwiftUI

/// Progress toward the score to beat.
///
/// Overshoot is shown, not clamped: once `progress` passes 1 a second, brighter lap
/// starts drawing on top. Beating your target by a lot should look different from
/// beating it by one rep.
struct ProgressRing: View {

    /// May exceed 1.
    let progress: Double
    var lineWidth: CGFloat = 14
    var isRecord: Bool = false

    private var firstLap: Double { min(max(progress, 0), 1) }
    private var secondLap: Double { min(max(progress - 1, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: firstLap)
                .stroke(Theme.accentGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if secondLap > 0 {
                Circle()
                    .trim(from: 0, to: secondLap)
                    .stroke(Theme.accentBright,
                            style: StrokeStyle(lineWidth: lineWidth * 0.55, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .shadow(color: isRecord ? Theme.accent.opacity(0.55) : .clear, radius: 18)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: progress)
        .accessibilityHidden(true)
    }
}

/// The small ring on the weekly goal card — discrete days rather than a continuous
/// fraction, because "3 of 4 days" is a count, not a percentage.
struct WeeklyGoalRing: View {

    let progress: WeeklyProgress
    var diameter: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress.fraction)
                .stroke(progress.isMet ? AnyShapeStyle(Theme.accentGradient)
                                       : AnyShapeStyle(Theme.accent.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress.isMet {
                Image(systemName: "checkmark")
                    .font(.system(size: diameter * 0.36, weight: .black))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 30) {
        ProgressRing(progress: 0.62).frame(width: 160, height: 160)
        ProgressRing(progress: 1.35, isRecord: true).frame(width: 160, height: 160)
        WeeklyGoalRing(progress: WeeklyProgress(daysCompleted: 2, goal: 4))
        WeeklyGoalRing(progress: WeeklyProgress(daysCompleted: 4, goal: 4))
    }
    .padding(40)
    .background(Theme.surface)
}

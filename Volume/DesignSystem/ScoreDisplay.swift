import SwiftUI

/// The hero number. The single most important pixel-area in the app.
struct ScoreDisplay: View {

    let score: Double
    var size: CGFloat = 88
    var isRecord: Bool = false
    var caption: String?

    /// Scales with Dynamic Type but is capped, so an accessibility text size enlarges
    /// the number without shoving the rest of the screen off the bottom.
    @ScaledMetric(relativeTo: .largeTitle) private var typeScale: CGFloat = 1

    private var resolvedSize: CGFloat {
        min(size * typeScale, size * 1.5)
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(VolumeScore.format(score))
                .font(Theme.numeral(resolvedSize))
                .monospacedDigit()
                .foregroundStyle(isRecord ? AnyShapeStyle(Theme.accentGradient)
                                          : AnyShapeStyle(Color.primary))
                .contentTransition(.numericText(value: score))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: score)

            if let caption {
                Text(caption.uppercased())
                    .font(Theme.label(13, weight: .heavy))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption ?? "Volume score")
        .accessibilityValue(VolumeScore.format(score))
    }
}

/// Compact score used in lists, cards and the calendar.
struct ScorePill: View {
    let score: Double
    var tint: Color = Theme.accent
    var prominent = false

    var body: some View {
        Text(VolumeScore.format(score))
            .font(Theme.label(prominent ? 19 : 16, weight: .heavy))
            .monospacedDigit()
            .foregroundStyle(prominent ? .white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(prominent ? AnyShapeStyle(Theme.accentGradient)
                                         : AnyShapeStyle(tint.opacity(0.14)))
            )
            .accessibilityLabel("Score \(VolumeScore.format(score))")
    }
}

#Preview {
    VStack(spacing: 40) {
        ScoreDisplay(score: 12480, caption: "Volume score")
        ScoreDisplay(score: 14820, isRecord: true, caption: "New record")
        ScorePill(score: 9310)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.surface)
}

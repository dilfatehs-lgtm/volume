import SwiftUI

/// The moment the live score passes the score to beat.
///
/// Transient by design: it lands, it feels good, and it gets out of the way so the user
/// can carry on lifting. Auto-dismisses, or tap anywhere to dismiss early.
struct RecordCelebrationView: View {

    let score: Double
    let previousScore: Double
    /// Record streak *including* this session, so the number shown is the one the user
    /// will see on Home afterwards.
    let streak: Int
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var delta: Double { score - previousScore }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            RadialGradient(colors: [Theme.accent.opacity(0.45), .clear],
                           center: .center, startRadius: 10, endRadius: 380)
                .ignoresSafeArea()
                .blendMode(.plusLighter)

            if !reduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 18) {
                Text("NEW RECORD 🔥")
                    .font(Theme.label(36, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Theme.accent.opacity(0.8), radius: 16)

                Text(VolumeScore.format(score))
                    .font(Theme.numeral(76))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accentGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                Text("\(VolumeScore.formatDelta(delta)) past your last score")
                    .font(Theme.label(18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                if streak > 1 {
                    Text("🔥 \(streak) IN A ROW")
                        .font(Theme.label(17, weight: .black))
                        .tracking(1.1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.white.opacity(0.16)))
                }

                Text("Tap to keep going")
                    .font(Theme.label(14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 6)
            }
            .padding(32)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
            .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New record. \(VolumeScore.format(score)). \(VolumeScore.formatDelta(delta)) past your last score.\(streak > 1 ? " \(streak) records in a row." : "")")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to dismiss and keep going")
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                appeared = true
            }
            UIAccessibility.post(notification: .announcement, argument: "New record")
        }
    }
}

#Preview {
    RecordCelebrationView(score: 14820, previousScore: 12480, streak: 4) {}
}

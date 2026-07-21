import SwiftUI

/// Reps and weight input: two oversized buttons and a tappable number.
///
/// Built for one thumb. Nudging by a step is a single tap on a 54pt target; typing an
/// exact number is one tap on the value itself. Nothing requires a keyboard.
struct BigStepper: View {

    let title: String
    let value: Double
    let step: Double
    let range: ClosedRange<Double>
    var suffix: String?
    var format: (Double) -> String
    var onChange: (Double) -> Void
    var onTapValue: () -> Void

    private var canDecrease: Bool { value - step >= range.lowerBound - 0.0001 }
    private var canIncrease: Bool { value + step <= range.upperBound + 0.0001 }

    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(Theme.label(12, weight: .heavy))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                stepButton(systemName: "minus", enabled: canDecrease) {
                    onChange(max(value - step, range.lowerBound))
                }

                Button(action: onTapValue) {
                    VStack(spacing: 0) {
                        Text(format(value))
                            .font(Theme.numeral(30))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        if let suffix {
                            Text(suffix)
                                .font(Theme.label(11, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                }
                .buttonStyle(.plain)

                stepButton(systemName: "plus", enabled: canIncrease) {
                    onChange(min(value + step, range.upperBound))
                }
            }
        }
        // One adjustable element rather than three controls, so VoiceOver users can
        // swipe up/down to change the value instead of hunting for tiny buttons.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(format(value)) \(suffix ?? "")")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment where canIncrease:
                onChange(min(value + step, range.upperBound))
            case .decrement where canDecrease:
                onChange(max(value - step, range.lowerBound))
            default:
                break
            }
        }
        .accessibilityAction(named: "Type a number", onTapValue)
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.4))
                .frame(width: 54, height: 54)
                .background(Circle().fill(Theme.cardRaised))
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityHidden(true)
    }
}

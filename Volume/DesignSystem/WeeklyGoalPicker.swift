import SwiftUI

/// Pick 1–7 days a week. Shared between onboarding and Settings so the control the user
/// learns during setup is the same one they come back to.
///
/// Every value from 1 to 7 is selectable and the app says nothing about the choice.
/// Warning someone off 7, or hinting at rest days, would be fitness advice — out of scope.
/// It just counts.
struct WeeklyGoalPicker: View {

    @Binding var days: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(StreakCalculator.goalRange, id: \.self) { value in
                    Button {
                        Haptics.selectionChanged()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            days = value
                        }
                    } label: {
                        Text("\(value)")
                            .font(Theme.numeral(22))
                            .monospacedDigit()
                            .foregroundStyle(value <= days ? .white : .primary)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(value <= days ? AnyShapeStyle(Theme.accentGradient)
                                                        : AnyShapeStyle(Theme.cardRaised))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(value == days ? Theme.accentDeep : Theme.hairline,
                                                  lineWidth: value == days ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                }
            }

            Text(days == 1 ? "1 day a week" : "\(days) days a week")
                .font(Theme.label(16, weight: .heavy))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(days)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly goal")
        .accessibilityValue(days == 1 ? "1 day a week" : "\(days) days a week")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment where days < StreakCalculator.goalRange.upperBound:
                days += 1
            case .decrement where days > StreakCalculator.goalRange.lowerBound:
                days -= 1
            default:
                break
            }
        }
    }
}

#Preview {
    @Previewable @State var days = 3
    return WeeklyGoalPicker(days: $days).padding()
}

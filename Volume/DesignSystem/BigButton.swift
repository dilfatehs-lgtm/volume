import SwiftUI

/// The app's button vocabulary. Everything is large, opaque and obviously tappable —
/// no icon-only affordances, no swipe-to-reveal, nothing hidden behind a gesture.
struct BigButtonStyle: ButtonStyle {

    enum Kind {
        case primary
        case secondary
        case destructive
    }

    var kind: Kind = .primary
    var size: CGFloat = 20
    var fullWidth = true

    // Custom ButtonStyles get no automatic disabled treatment. Without this a disabled
    // button renders identically to a live one and taps die in silence — App Review
    // reported the paywall's Subscribe button as "unresponsive" for exactly that reason.
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.label(size, weight: .heavy))
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 56)
            .padding(.horizontal, 24)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                    .strokeBorder(kind == .secondary ? Theme.hairline : .clear, lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }

    @ViewBuilder private var background: some View {
        switch kind {
        case .primary: Theme.accentGradient
        case .secondary: Theme.cardRaised
        case .destructive: Color.red.opacity(0.12)
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: .white
        case .secondary: .primary
        case .destructive: .red
        }
    }
}

extension ButtonStyle where Self == BigButtonStyle {
    static var big: BigButtonStyle { BigButtonStyle() }
    static var bigSecondary: BigButtonStyle { BigButtonStyle(kind: .secondary) }
    static var bigDestructive: BigButtonStyle { BigButtonStyle(kind: .destructive) }
}

/// Section heading used across the tabs.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.label(13, weight: .heavy))
            .tracking(1.2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Friendly placeholder for the several screens that can legitimately be empty.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Theme.label(22, weight: .heavy))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

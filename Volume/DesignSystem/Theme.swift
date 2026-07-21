import SwiftUI

enum Theme {

    // MARK: - Colour
    //
    // Defined as dynamic colours rather than fixed values so they resolve per-trait and
    // follow a live light/dark switch without the views knowing anything about it.

    static let accent = dynamic(light: (0xFF, 0x6B, 0x1A), dark: (0xFF, 0x7F, 0x33))
    /// Lighter end of the ring gradient, and the second lap when a score overshoots.
    static let accentBright = dynamic(light: (0xFF, 0x9B, 0x4D), dark: (0xFF, 0xA9, 0x5E))
    static let accentDeep = dynamic(light: (0xE0, 0x51, 0x00), dark: (0xFF, 0x5A, 0x00))

    static let surface = dynamic(light: (0xF6, 0xF6, 0xF8), dark: (0x0B, 0x0B, 0x0C))
    static let card = dynamic(light: (0xFF, 0xFF, 0xFF), dark: (0x17, 0x17, 0x1A))
    static let cardRaised = dynamic(light: (0xFF, 0xFF, 0xFF), dark: (0x21, 0x21, 0x25))
    static let hairline = dynamic(light: (0xE3, 0xE3, 0xE8), dark: (0x2C, 0x2C, 0x32))

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accentDeep, accent, accentBright],
                       startPoint: .bottomLeading, endPoint: .topTrailing)
    }

    /// Confetti palette — the accent plus warm neighbours so the burst reads as one
    /// family rather than a rainbow.
    static let confettiColors: [Color] = [
        Color(red: 1.00, green: 0.42, blue: 0.10),
        Color(red: 1.00, green: 0.61, blue: 0.20),
        Color(red: 1.00, green: 0.78, blue: 0.30),
        Color(red: 1.00, green: 0.30, blue: 0.35),
        Color(red: 1.00, green: 0.90, blue: 0.60),
    ]

    // MARK: - Metrics

    /// Floor for every interactive control in the app.
    static let minTapTarget: CGFloat = 50
    static let cardRadius: CGFloat = 22
    static let buttonRadius: CGFloat = 20
    static let gutter: CGFloat = 20

    // MARK: - Type

    /// Heavy rounded numerals, used for every score in the app.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    private static func dynamic(light: (Int, Int, Int), dark: (Int, Int, Int)) -> Color {
        Color(uiColor: UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat(c.0) / 255,
                           green: CGFloat(c.1) / 255,
                           blue: CGFloat(c.2) / 255,
                           alpha: 1)
        })
    }
}

// MARK: - Shared modifiers

struct CardBackground: ViewModifier {
    var raised = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(raised ? Theme.cardRaised : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardBackground(raised: Bool = false) -> some View {
        modifier(CardBackground(raised: raised))
    }

    /// Guarantees the 50pt minimum tap target the whole app is designed around.
    func bigTapTarget() -> some View {
        frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
            .contentShape(Rectangle())
    }
}

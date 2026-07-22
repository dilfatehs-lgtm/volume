import SwiftUI

/// The three ascending bars from the app icon, drawn rather than shipped as an image so it
/// scales cleanly and picks up the accent gradient.
struct VolumeLogo: View {

    var height: CGFloat = 64

    private var barWidth: CGFloat { height * 0.22 }
    private var spacing: CGFloat { height * 0.10 }
    /// Same proportions as `AppIcon.png`.
    private let ratios: [CGFloat] = [0.44, 0.72, 1.0]

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(ratios.enumerated()), id: \.offset) { index, ratio in
                Capsule(style: .continuous)
                    .fill(index == 2 ? AnyShapeStyle(Theme.accentBright)
                                     : AnyShapeStyle(Theme.accent))
                    .frame(width: barWidth, height: height * ratio)
            }
        }
        .frame(height: height, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 30) {
        VolumeLogo()
        VolumeLogo(height: 100)
    }
    .padding()
    .background(Theme.surface)
}

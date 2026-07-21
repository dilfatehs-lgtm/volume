import SwiftUI

/// Hand-rolled confetti: a single `Canvas` driven by `TimelineView(.animation)`.
///
/// One drawing pass per frame for the whole burst, rather than N animated SwiftUI views,
/// which keeps it smooth on top of a live-updating workout screen.
struct ConfettiView: View {

    var particleCount: Int = 140
    /// Longest a particle can take to cross the screen; the view is done after this
    /// plus the maximum launch delay.
    var fallDuration: ClosedRange<Double> = 1.6...2.8

    @State private var particles: [Particle] = []
    @State private var start = Date()

    private struct Particle {
        var x: Double
        var colorIndex: Int
        var width: Double
        var height: Double
        var delay: Double
        var duration: Double
        var spin: Double
        var driftAmount: Double
        var driftRate: Double
        var initialAngle: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)

                for particle in particles {
                    let localTime = elapsed - particle.delay
                    guard localTime > 0 else { continue }

                    let progress = localTime / particle.duration
                    guard progress < 1 else { continue }

                    // Start just above the top edge, finish just past the bottom.
                    let y = (-0.08 + progress * 1.16) * size.height
                    let sway = sin(progress * .pi * 2 * particle.driftRate) * particle.driftAmount
                    let x = (particle.x + sway) * size.width

                    // Fade out over the last fifth so nothing pops off-screen.
                    let fade = progress > 0.8 ? (1 - (progress - 0.8) / 0.2) : 1

                    var layer = context
                    layer.opacity = fade
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .radians(particle.initialAngle + progress * particle.spin))

                    let rect = CGRect(x: -particle.width / 2,
                                      y: -particle.height / 2,
                                      width: particle.width,
                                      height: particle.height)
                    layer.fill(Path(roundedRect: rect, cornerRadius: 1.5),
                               with: .color(Theme.confettiColors[particle.colorIndex]))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            particles = Self.makeParticles(count: particleCount, durationRange: fallDuration)
            start = Date()
        }
    }

    private static func makeParticles(count: Int,
                                      durationRange: ClosedRange<Double>) -> [Particle] {
        (0..<count).map { _ in
            Particle(x: Double.random(in: -0.05...1.05),
                     colorIndex: Int.random(in: 0..<Theme.confettiColors.count),
                     width: Double.random(in: 6...12),
                     height: Double.random(in: 9...18),
                     delay: Double.random(in: 0...0.7),
                     duration: Double.random(in: durationRange),
                     spin: Double.random(in: -10...10),
                     driftAmount: Double.random(in: 0.02...0.09),
                     driftRate: Double.random(in: 0.8...2.2),
                     initialAngle: Double.random(in: 0...(2 * .pi)))
        }
    }
}

#Preview {
    ZStack {
        Theme.surface
        ConfettiView()
    }
    .ignoresSafeArea()
}

import UIKit

/// Every piece of physical feedback in the app, in one place.
enum Haptics {

    /// A set was logged. The most frequent feedback in the app, so it stays light-medium.
    static func setLogged() {
        impact(.medium)
    }

    /// Crossed 25% / 50% / 75% of the score to beat.
    static func milestone() {
        impact(.light)
    }

    /// General button confirmation.
    static func tap() {
        impact(.light, intensity: 0.7)
    }

    static func selectionChanged() {
        DispatchQueue.main.async {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }

    /// The moment the live score passes the score to beat: a success chime followed by
    /// a quick rising burst. Deliberately the biggest haptic in the app — nothing else
    /// is allowed to feel this good.
    static func newRecord() {
        DispatchQueue.main.async {
            let notification = UINotificationFeedbackGenerator()
            notification.prepare()
            notification.notificationOccurred(.success)
        }
        let burst: [(delay: Double, intensity: CGFloat)] = [
            (0.12, 0.6), (0.22, 0.8), (0.32, 1.0)
        ]
        for beat in burst {
            DispatchQueue.main.asyncAfter(deadline: .now() + beat.delay) {
                impact(.heavy, intensity: beat.intensity)
            }
        }
    }

    /// Workout finished without a record — solid, satisfying, but not a celebration.
    static func finished() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    static func warning() {
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle,
                               intensity: CGFloat = 1.0) {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        }
    }
}

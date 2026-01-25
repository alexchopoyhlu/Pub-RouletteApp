import UIKit

/// Centralized haptic feedback utility for consistent haptics throughout the app
enum Haptics {

    // MARK: - Impact Feedback

    /// Light impact - for subtle interactions like selections, toggles
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - for standard button taps, confirmations
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - for major actions, important state changes
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success feedback - for completed actions, successful submissions
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning feedback - for destructive actions, errors
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error feedback - for failed actions
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed - for picker changes, slider ticks
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

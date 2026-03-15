import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        // Pre-warm generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Light tap for simple player movement
    func playerMoved() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium impact for pushing a box
    func boxPushed() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Success notification when a box lands on a goal
    func boxOnGoal() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Heavy impact + success for level completion
    func levelCompleted() {
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            heavyImpact.impactOccurred()
            heavyImpact.prepare()
        }
        notification.prepare()
    }

    /// Light warning tap for blocked move
    func blocked() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
}

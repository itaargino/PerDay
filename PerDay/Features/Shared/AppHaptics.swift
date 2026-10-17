import UIKit

/// Feedback is tied to completed actions, never to rendering or text entry.
@MainActor
enum AppHaptics {
  static func tap() {
    guard !AppPlatform.isMac, UIApplication.shared.applicationState == .active else { return }
    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.55)
  }

  static func selection() {
    guard !AppPlatform.isMac, UIApplication.shared.applicationState == .active else { return }
    UISelectionFeedbackGenerator().selectionChanged()
  }

  static func success() { notify(.success) }
  static func warning() { notify(.warning) }
  static func error() { notify(.error) }

  private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    guard !AppPlatform.isMac, UIApplication.shared.applicationState == .active else { return }
    UINotificationFeedbackGenerator().notificationOccurred(type)
  }
}

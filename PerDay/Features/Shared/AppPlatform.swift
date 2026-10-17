import SwiftUI
import UIKit

/// Centralizes the desktop adaptations shared by Catalyst and iOS-on-Mac.
@MainActor
enum AppPlatform {
  static var isMac: Bool {
    #if targetEnvironment(macCatalyst)
      true
    #else
      ProcessInfo.processInfo.isiOSAppOnMac
    #endif
  }

  static func endEditing() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

extension View {
  /// Catalyst sheets need a useful content size independently of iOS detents.
  func journalSheet(minHeight: CGFloat = 480) -> some View {
    frame(
      minWidth: AppPlatform.isMac ? 460 : nil,
      idealWidth: AppPlatform.isMac ? 540 : nil,
      minHeight: AppPlatform.isMac ? minHeight : nil,
      idealHeight: AppPlatform.isMac ? minHeight : nil)
  }
}

/// Keep desktop windows wide enough for date navigation and block editing.
struct JournalWindowConfiguration: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView { WindowView() }
  func updateUIView(_ uiView: UIView, context: Context) {}

  private final class WindowView: UIView {
    override func didMoveToWindow() {
      super.didMoveToWindow()
      guard AppPlatform.isMac else { return }
      window?.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 640, height: 520)
    }
  }
}

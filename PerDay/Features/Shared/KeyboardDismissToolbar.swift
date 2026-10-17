import SwiftUI

struct KeyboardDismissToolbar: ViewModifier {
  func body(content: Content) -> some View {
    if AppPlatform.isMac {
      content
    } else {
      content.toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button {
            AppPlatform.endEditing()
            AppHaptics.tap()
          } label: {
            Label("Done", systemImage: "keyboard.chevron.compact.down")
          }
          .accessibilityLabel("Dismiss keyboard")
        }
      }
    }
  }
}

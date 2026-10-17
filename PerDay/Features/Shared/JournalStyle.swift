import SwiftUI

/// Shared layout values for the journal, editors, and supporting sheets.
enum JournalStyle {
  static let spacing: CGFloat = 8
  static let sectionSpacing: CGFloat = 16
  static let margin: CGFloat = 16
  static let cornerRadius: CGFloat = 16
  static let touchTarget: CGFloat = 44
}

extension View {
  func journalCard() -> some View {
    padding(JournalStyle.margin)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        Color(uiColor: .secondarySystemGroupedBackground),
        in: RoundedRectangle(cornerRadius: JournalStyle.cornerRadius))
  }
}

/// Compact content rows retain a visible press state without a glass background.
struct JournalRowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .opacity(configuration.isPressed ? 0.55 : 1)
  }
}

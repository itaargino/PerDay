import SwiftUI

/// Intercepts taps while deletion is armed, so checkboxes/editors cannot fire.
struct BlockDeletionTarget: ViewModifier {
  let isActive: Bool
  let label: String
  let hint: String
  let onDelete: () -> Void

  func body(content: Content) -> some View {
    content
      .allowsHitTesting(!isActive)
      .accessibilityHidden(isActive)
      .overlay { if isActive { deleteButton } }
  }

  private var deleteButton: some View {
    Button(role: .destructive, action: onDelete) { deleteOutline }
      .buttonStyle(JournalRowButtonStyle())
      .accessibilityLabel(label)
      .accessibilityHint(hint)
  }

  private var deleteOutline: some View {
    RoundedRectangle(cornerRadius: JournalStyle.cornerRadius)
      .fill(Color.red.opacity(0.04))
      .overlay {
        RoundedRectangle(cornerRadius: JournalStyle.cornerRadius)
          .strokeBorder(Color.red.opacity(0.7), lineWidth: 1.5)
      }
      .overlay(alignment: .topTrailing) {
        BlockActionSymbol(symbol: "trash.fill", tint: .red).padding(8)
      }
      .contentShape(RoundedRectangle(cornerRadius: JournalStyle.cornerRadius))
  }
}

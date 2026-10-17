import SwiftUI

/// Shared empty component slot, before and after saving a block.
struct AddComponentPlaceholder: View {
  var body: some View {
    Label("Add component", systemImage: "plus")
      .foregroundStyle(Color.accentColor)
      .frame(maxWidth: .infinity, minHeight: 52)
      .contentShape(Rectangle())
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
          .allowsHitTesting(false)
      }
  }
}

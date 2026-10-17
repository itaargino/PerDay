import SwiftUI

/// Edit and delete use the same geometry: 44pt circle, 8pt from the card edge.
struct BlockActionSymbol: View {
  let symbol: String
  let tint: Color

  var body: some View {
    Image(systemName: symbol)
      .font(.body)
      .foregroundStyle(.white)
      .frame(width: JournalStyle.touchTarget, height: JournalStyle.touchTarget)
      .background(tint, in: Circle())
      .contentShape(Circle())
  }
}

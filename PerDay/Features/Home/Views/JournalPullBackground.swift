import SwiftUI

struct JournalPullBackground: View {
  let distance: CGFloat

  var body: some View {
    ZStack {
      Color(uiColor: .systemGroupedBackground)
      LinearGradient(
        colors: [
          .blue.opacity(0.04 + 0.10 * min(distance / 200, 1)),
          .blue.opacity(0.025), .clear,
        ],
        startPoint: .top, endPoint: .bottom
      )
      .opacity(distance > 2 ? min(distance / 24, 1) : 0)
      .animation(.easeOut(duration: 0.18), value: distance)
    }
    .ignoresSafeArea()
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

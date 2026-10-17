import SwiftUI

struct TimestampBoundsKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>? { nil }

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    value = nextValue() ?? value
  }
}

struct TimelineConnector: View {
  let anchor: Anchor<CGRect>?

  var body: some View {
    GeometryReader { geometry in
      if let anchor { connector(centerY: geometry[anchor].midY, height: geometry.size.height) }
    }
    .accessibilityHidden(true)
    .allowsHitTesting(false)
  }

  private func connector(centerY: CGFloat, height: CGFloat) -> some View {
    ZStack {
      Path { path in
        path.move(to: CGPoint(x: 4, y: centerY))
        path.addLine(to: CGPoint(x: 4, y: height))
      }
      .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
      Circle().fill(Color.accentColor)
        .frame(width: 8, height: 8)
        .position(x: 4, y: centerY)
    }
  }
}

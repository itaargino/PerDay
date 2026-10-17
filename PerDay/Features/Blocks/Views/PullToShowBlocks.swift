import SwiftUI
import UIKit

/// Lets Home paint the pull feedback behind its fixed calendar and safe areas.
struct BlockPullDistanceKey: PreferenceKey {
  static var defaultValue: CGFloat { 0 }
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

/// Observes the scroll view's top overscroll without competing with its pan gesture.
private struct PullToShowBlocks: ViewModifier {
  let onSelect: (BlockKind) -> Void
  let onDelete: () -> Void
  let canDelete: Bool
  let journalDay: Date
  let onCreateCapture: (BlockDraft) throws -> Void
  @Binding var captureText: String
  @Binding var showingBlocks: Bool
  @Binding var hintOffset: CGFloat
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var hasShownHint: Bool = false
  @State private var userInteracted: Bool = false
  @State private var hintDistance: CGFloat = 0
  @State private var distance: CGFloat = 0
  @State private var isPulling: Bool = false
  @State private var highestStep = 0
  @State private var feedback = UIImpactFeedbackGenerator(style: .light)

  private let threshold: CGFloat = 160
  private let stepSize: CGFloat = 18

  func body(content: Content) -> some View {
    content
      .scrollBounceBehavior(.always, axes: .vertical)
      .onScrollGeometryChange(for: CGFloat.self) { geometry in
        max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
      } action: { _, newDistance in
        updatePullDistance(newDistance)
      }
      .onScrollPhaseChange { updateScrollPhase(from: $0, to: $1) }
      .overlay(alignment: .top) { pullIndicator }
      .preference(key: BlockPullDistanceKey.self, value: showingBlocks ? 0 : visualDistance)
      .task { await showOpeningHint() }
      .sheet(isPresented: $showingBlocks) { blockPickerSheet }
  }

  private var blockPickerSheet: some View {
    BlockPickerView(
      canDelete: canDelete, journalDay: journalDay,
      captureText: $captureText, onCreateCapture: onCreateCapture,
      onSelect: { kind in
        guard showingBlocks else { return }
        showingBlocks = false
        onSelect(kind)
      },
      onDelete: {
        showingBlocks = false
        onDelete()
      }
    )
    .journalSheet(minHeight: 560)
    .presentationDetents([.large])
    .presentationDragIndicator(.visible)
  }

  private func updatePullDistance(_ newDistance: CGFloat) {
    guard !AppPlatform.isMac, isPulling, !showingBlocks else { return }
    distance = newDistance
    let step = Int(min(newDistance, threshold) / stepSize)
    if step > highestStep {
      highestStep = step
      feedback.impactOccurred(intensity: 0.25 + 0.75 * min(newDistance / threshold, 1))
      feedback.prepare()
    }
    if newDistance >= threshold { openBlocks() }
  }

  private func updateScrollPhase(from oldPhase: ScrollPhase, to newPhase: ScrollPhase) {
    guard !AppPlatform.isMac else { return }
    if newPhase == .tracking || (newPhase == .interacting && !isPulling) { beginPull() }
    guard (oldPhase == .interacting && newPhase != .interacting) || newPhase == .idle else {
      return
    }
    isPulling = false
    distance = 0
    highestStep = 0
  }

  private func beginPull() {
    userInteracted = true
    hintDistance = 0
    hintOffset = 0
    isPulling = true
    distance = 0
    highestStep = 0
    feedback.prepare()
  }

  private var visualDistance: CGFloat { max(distance, hintDistance) }

  private var pullIndicator: some View {
    ZStack(alignment: .top) {
      pullProgress
        .foregroundStyle(.primary)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    .frame(maxWidth: .infinity)
    .frame(height: max(110, visualDistance + 48))
    .opacity(visualDistance > 2 && !showingBlocks ? min(visualDistance / 24, 1) : 0)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var pullProgress: some View {
    VStack(spacing: 8) {
      if isPulling {
        Text("Pull to setup your blocks")
          .font(.subheadline.weight(.medium))
          .fixedSize(horizontal: false, vertical: true)
        ProgressView(value: min(distance / threshold, 1))
          .tint(.blue)
          .frame(width: 100)
      }
    }
  }

  @MainActor
  private func showOpeningHint() async {
    guard !AppPlatform.isMac, !hasShownHint else { return }
    hasShownHint = true
    do {
      try await Task.sleep(for: .milliseconds(200))
      guard !userInteracted, !showingBlocks else { return }
      withAnimation(.easeInOut(duration: 0.45)) {
        hintDistance = 28
        hintOffset = reduceMotion ? 0 : 30
      }
      try await Task.sleep(for: .milliseconds(500))
      guard !userInteracted, !showingBlocks else { return }
      withAnimation(.easeInOut(duration: reduceMotion ? 0.25 : 0.5)) {
        hintDistance = 0
        hintOffset = 0
      }
    } catch {
      hintDistance = 0
      hintOffset = 0
    }
  }

  private func openBlocks() {
    guard !showingBlocks else { return }
    isPulling = false
    distance = 0
    AppHaptics.tap()
    showingBlocks = true
  }
}

extension View {
  func pullToShowBlocks(
    hintOffset: Binding<CGFloat>, canDelete: Bool,
    journalDay: Date, captureText: Binding<String>, showingBlocks: Binding<Bool>,
    onCreateCapture: @escaping (BlockDraft) throws -> Void,
    onDelete: @escaping () -> Void,
    onSelect: @escaping (BlockKind) -> Void
  ) -> some View {
    modifier(
      PullToShowBlocks(
        onSelect: onSelect, onDelete: onDelete,
        canDelete: canDelete, journalDay: journalDay,
        onCreateCapture: onCreateCapture, captureText: captureText,
        showingBlocks: showingBlocks, hintOffset: hintOffset))
  }
}

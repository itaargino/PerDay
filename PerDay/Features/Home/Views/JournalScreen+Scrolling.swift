import SwiftUI

extension JournalScreen {
  var pagedTimeline: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        currentTimeline
          .offset(x: dayOffset)
          .allowsHitTesting(!isSettlingDay)
        neighborPreview(width: geometry.size.width)
      }
      .clipped()
      .contentShape(Rectangle())
      .simultaneousGesture(daySwipe(width: geometry.size.width))
    }
  }

  private var currentTimeline: some View {
    ScrollViewReader { proxy in
      scrollableTimeline(proxy: proxy)
        .onChange(of: journal.drafts.count) { _, _ in scrollToNewestDraft(proxy: proxy) }
        .onChange(of: journal.selectedDate) { _, _ in
          AppHaptics.selection()
          proxy.scrollTo("timelineTop", anchor: .top)
        }
    }
  }

  private func scrollableTimeline(proxy: ScrollViewProxy) -> some View {
    ScrollView {
      timelineContent(for: journal.selectedDate)
        .id("timelineTop")
        .offset(y: pullHintOffset)
    }
    .scrollDismissesKeyboard(.interactively)
    .pullToShowBlocks(
      hintOffset: $pullHintOffset, canDelete: !journal.timeline.isEmpty,
      journalDay: journal.selectedDate, captureText: $intelligentCaptureText,
      showingBlocks: $showingBlockPicker, onCreateCapture: journal.saveVoiceBlock,
      onDelete: beginDeletion
    ) { kind in selectDraft(kind, proxy: proxy) }
  }

  @ViewBuilder
  private func neighborPreview(width: CGFloat) -> some View {
    if let previewDirection,
      let neighbor = journal.calendar.date(
        byAdding: .day, value: previewDirection, to: journal.selectedDate)
    {
      ScrollView { timelineContent(for: neighbor, isPreview: true) }
        .offset(x: dayOffset + (previewDirection == 1 ? width : -width))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private func selectDraft(_ kind: BlockKind, proxy: ScrollViewProxy) {
    journal.isDeleting = false
    // Resume the unfinished block instead of creating another draft.
    let draft = journal.drafts.first ?? BlockDraft(kind: kind, day: journal.selectedDate)
    if journal.drafts.isEmpty { journal.drafts.append(draft) }
    journal.selectedDate = draft.journalDate
    withAnimation { proxy.scrollTo(draft.id, anchor: .top) }
  }

  private func scrollToNewestDraft(proxy: ScrollViewProxy) {
    guard !journal.isDeleting else { return }
    guard
      let newest = journal.drafts.last(where: {
        journal.calendar.isDate($0.journalDate, inSameDayAs: journal.selectedDate)
      })
    else { return }
    withAnimation { proxy.scrollTo(newest.id, anchor: .top) }
  }
}

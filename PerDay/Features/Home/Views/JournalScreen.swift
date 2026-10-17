import SwiftData
import SwiftUI
import UIKit

struct JournalScreen: View {
  let blocks: [NoteBlockModel]
  @State var journal: JournalController
  @State var showingVoice: Bool = false
  @State var showingBlockPicker: Bool = false
  @State var intelligentCaptureText: String = ""
  @State var reviewCaptureAfterVoice: Bool = false
  @State var pullHintOffset: CGFloat = 0
  @State var blockPullDistance: CGFloat = 0
  @State var dayOffset: CGFloat = 0
  @State var previewDirection: Int?
  @State var dayDragAxis: Axis?
  @State var isSettlingDay: Bool = false
  @State var isEditingBlock: Bool = false
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  init(blocks: [NoteBlockModel], repository: JournalRepository) {
    self.blocks = blocks
    _journal = State(
      initialValue: JournalController(
        repository: repository, blocks: blocks, feedback: JournalHapticFeedback()))
  }
  var body: some View {
    NavigationStack { journalContent }
      .onChange(of: blocks.map(\.id)) { _, _ in journal.blocks = blocks }
      .sheet(isPresented: $showingVoice, onDismiss: finishVoiceReview) { voiceSheet }
      .alert("Couldn’t Update Journal", isPresented: saveErrorPresented) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(journal.saveError ?? "Please try again.")
      }
  }

  private var journalContent: some View {
    VStack(spacing: 0) {
      dateHeader
      if AppPlatform.isMac { desktopControls }
      pagedTimeline
    }
    .animation(presentationAnimation, value: journal.isDeleting)
    .overlay(alignment: .bottomTrailing) { voiceButton }
    .safeAreaInset(edge: .bottom) { undoPresentation }
    .animation(presentationAnimation, value: journal.lastRemoved != nil)
    .task(id: journal.undoPresentationID) { await expireUndoPresentation() }
    .onPreferenceChange(BlockEditingKey.self) { isEditingBlock = $0 }
    .onPreferenceChange(BlockPullDistanceKey.self) { blockPullDistance = $0 }
    .background { JournalPullBackground(distance: blockPullDistance) }
    .modifier(KeyboardDismissToolbar())
    .toolbar(.hidden, for: .navigationBar)
  }

  private var dateHeader: some View {
    JournalDateHeader(
      selectedDate: $journal.selectedDate, canDelete: !journal.timeline.isEmpty,
      isDeleting: journal.isDeleting, onDelete: beginDeletion,
      onFinishDeletion: {
        journal.isDeleting = false
        AppHaptics.tap()
      },
      onOpenCalendar: { AppHaptics.tap() }
    )
    .frame(maxWidth: AppPlatform.isMac ? 860 : .infinity)
  }

  private var presentationAnimation: Animation {
    reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.3)
  }

  private var saveErrorPresented: Binding<Bool> {
    Binding(get: { journal.saveError != nil }, set: { if !$0 { journal.saveError = nil } })
  }

  private var voiceSheet: some View {
    VoiceBlockView(journalDay: journal.selectedDate, onCreate: journal.saveVoiceBlock) { words in
      intelligentCaptureText = words
      reviewCaptureAfterVoice = true
    }
    .journalSheet(minHeight: 400)
    .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(400), .large])
    .presentationDragIndicator(.visible)
  }

  private func finishVoiceReview() {
    guard reviewCaptureAfterVoice else { return }
    reviewCaptureAfterVoice = false
    showingBlockPicker = true
  }

  private func expireUndoPresentation() async {
    guard let presentationID = journal.undoPresentationID else { return }
    do { try await Task.sleep(for: .seconds(UIAccessibility.isVoiceOverRunning ? 10 : 5)) } catch {
      return
    }
    guard journal.undoPresentationID == presentationID else { return }
    journal.lastRemoved = nil
    journal.undoPresentationID = nil
  }
}

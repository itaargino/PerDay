import SwiftUI

extension JournalScreen {
  func timelineContent(for day: Date, isPreview: Bool = false) -> some View {
    LazyVStack(alignment: .leading, spacing: 0) {
      if journal.entries(on: day).isEmpty { emptyTimeline }
      ForEach(journal.entries(on: day)) { entry in
        timelineRow(entry, day: day, isPreview: isPreview)
      }
    }
    .animation(timelineAnimation, value: journal.entries(on: day).map(\.id))
    .padding(JournalStyle.margin)
    .padding(.bottom, 80)
    .frame(maxWidth: AppPlatform.isMac ? 860 : .infinity, alignment: .leading)
    .frame(maxWidth: .infinity)
    .allowsHitTesting(!isPreview)
  }

  private var timelineAnimation: Animation {
    reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.85)
  }

  private var emptyTimeline: some View {
    ContentUnavailableView(
      "No Blocks for This Day", systemImage: "square.stack",
      description: Text(emptyTimelineInstruction)
    )
    .frame(maxWidth: .infinity)
  }

  private var emptyTimelineInstruction: String {
    if journal.isDeleting {
      return "Choose another day to delete more blocks, or choose Done to return."
    }
    return AppPlatform.isMac
      ? "Choose New Block to start writing here."
      : "Pull down to choose a block and write here."
  }

  private func timelineRow(_ entry: JournalEntry, day: Date, isPreview: Bool) -> some View {
    timelineRowContent(entry, day: day, isPreview: isPreview)
      .padding(.leading, 20)
      .padding(.bottom, JournalStyle.sectionSpacing)
      .overlayPreferenceValue(TimestampBoundsKey.self) { TimelineConnector(anchor: $0) }
      .transition(
        reduceMotion
          ? .opacity
          : .asymmetric(
            insertion: .opacity,
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -12)))
      )
      .id(entry.id)
  }

  private func timelineRowContent(_ entry: JournalEntry, day: Date, isPreview: Bool) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      entryTimestamp(entry)
      entryContent(entry, day: day, isPreview: isPreview)
        .modifier(
          BlockDeletionTarget(
            isActive: journal.isDeleting,
            label: entry.deletionLabel, hint: entry.deletionHint,
            onDelete: { journal.deleteEntry(entry) }))
    }
  }

  private func entryTimestamp(_ entry: JournalEntry) -> some View {
    Text(entry.createdAt, format: .dateTime.hour().minute())
      .font(.subheadline)
      .accessibilityLabel(
        "Created at \(entry.createdAt.formatted(date: .omitted, time: .shortened))"
      )
      .foregroundStyle(.secondary)
      .anchorPreference(key: TimestampBoundsKey.self, value: .bounds) { $0 }
  }

  @ViewBuilder
  private func entryContent(_ entry: JournalEntry, day: Date, isPreview: Bool) -> some View {
    switch entry {
    case .draft(let draft): draftContent(draft, isPreview: isPreview)
    case .block(let block): savedBlockContent(block, day: day)
    }
  }

  @ViewBuilder
  private func draftContent(_ draft: BlockDraft, isPreview: Bool) -> some View {
    if isPreview {
      DraftPreviewCard(draft: draft)
    } else {
      BlockEditorView(
        draft: draftBinding(for: draft),
        onSave: { journal.saveDraft(draft.id) },
        onCancel: { journal.drafts.removeAll { $0.id == draft.id } })
    }
  }

  private func savedBlockContent(_ block: NoteBlockModel, day: Date) -> some View {
    TimelineBlockView(
      block: block, completionDay: day, isDeleting: journal.isDeleting,
      onSaveComponents: { journal.saveComponents($0, in: block, on: day, scope: $1) },
      onOpenSchedule: { journal.openSchedule(for: block) },
      onToggleSkip: { journal.toggleSkippedOccurrence(in: block, on: day) },
      onToggleItem: { journal.toggleComponentTask($0, itemID: $1, in: block, day: day) },
      onDelete: { journal.deleteEntry(.block(block)) })
  }
}

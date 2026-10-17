import SwiftUI

/// One card is a parent block; its components always render in stored order.
struct TimelineBlockView: View {
  let block: NoteBlockModel
  let completionDay: Date
  let isDeleting: Bool
  let onSaveComponents: (BlockDraft, OccurrenceEditScope?) -> Bool
  let onOpenSchedule: () -> Void
  let onToggleSkip: () -> Void
  let onToggleItem: (UUID, UUID) -> Void
  let onDelete: () -> Void
  @State private var editingDraft: BlockDraft?
  @State private var editScope: OccurrenceEditScope?
  @State private var choosingEditScope: Bool = false
  @State private var isRescheduling: Bool = false

  private var isCreationRecord: Bool { block.isCreationRecord(on: completionDay) }

  private var isSkipped: Bool { block.isSkipped(on: completionDay) && !isCreationRecord }
  private var isRecurring: Bool { block.componentRecurrence != .never }

  var body: some View {
    Group {
      if editingDraft != nil { inlineEditor } else { blockCard }
    }
    .confirmationDialog(
      "Edit recurring block", isPresented: $choosingEditScope, titleVisibility: .visible
    ) {
      Button("This occurrence") { beginEditing(scope: .thisOccurrence) }
      Button("This and future occurrences") { beginEditing(scope: .thisAndFuture) }
      Button("Cancel", role: .cancel) {}
    }
  }

  private var inlineEditor: some View {
    BlockEditorView(
      draft: Binding(
        get: { editingDraft ?? BlockDraft(block: block) },
        set: { editingDraft = $0 }),
      onSave: {
        if let draft = editingDraft, onSaveComponents(draft, editScope) { editingDraft = nil }
      }, onCancel: { editingDraft = nil })
  }

  private var blockCard: some View {
    cardContent
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.trailing, !block.components.isEmpty ? 36 : 0)
      .journalCard()
      .overlay { creationOutline }
      .contentShape(RoundedRectangle(cornerRadius: 20))
      .onTapGesture { if isCreationRecord && !isDeleting { onOpenSchedule() } }
      .contextMenu {
        actionButtons.disabled(isDeleting)
        if AppPlatform.isMac {
          Button("Delete Block", systemImage: "trash", role: .destructive, action: onDelete)
        }
      }
      .overlay(alignment: .topTrailing) { actionsMenu }
      .accessibilityAction(named: "Edit block", editBlock)
  }

  private var cardContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      if isCreationRecord { creationReceipt }
      if isSkipped {
        Label("Skipped", systemImage: "forward.end").font(.subheadline).foregroundStyle(.secondary)
      }
      if block.components.isEmpty { emptyBlockButton }
      ForEach(block.components) { component in
        TimelineComponentView(
          component: component, block: block, completionDay: completionDay,
          isCreationRecord: isCreationRecord, isSkipped: isSkipped, onToggleItem: onToggleItem)
      }
    }
  }

  private var emptyBlockButton: some View {
    Button {
      editingDraft = BlockDraft(block: block)
      AppHaptics.tap()
    } label: {
      AddComponentPlaceholder()
    }
    .buttonStyle(.plain)
  }

  private var creationReceipt: some View {
    Group {
      VStack(alignment: .leading, spacing: 4) {
        Label("Creation record", systemImage: "calendar.badge.plus").font(
          .subheadline.weight(.medium))
        Text(
          "Created on this day · Scheduled from \(block.componentStart().formatted(date: .abbreviated, time: .omitted))"
        )
        .font(.caption).fixedSize(horizontal: false, vertical: true)
      }
      .foregroundStyle(.secondary).padding(.bottom, 4)
      Button("View scheduled occurrence", systemImage: "arrow.right", action: onOpenSchedule)
        .buttonStyle(.borderless).disabled(isDeleting)
    }
  }

  @ViewBuilder
  private var creationOutline: some View {
    if isCreationRecord {
      RoundedRectangle(cornerRadius: JournalStyle.cornerRadius)
        .strokeBorder(
          Color.secondary.opacity(0.6),
          style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [1, 5])
        )
        .allowsHitTesting(false).accessibilityHidden(true)
    }
  }

  @ViewBuilder
  private var actionButtons: some View {
    Button("Edit Block", systemImage: "pencil", action: editBlock)
    Button("Reschedule", systemImage: "calendar", action: rescheduleBlock)
    if isRecurring && !isCreationRecord {
      Button(
        isSkipped ? "Restore occurrence" : "Skip occurrence",
        systemImage: isSkipped ? "arrow.uturn.backward" : "forward.end", action: onToggleSkip)
    }
  }

  @ViewBuilder
  private var actionsMenu: some View {
    if !isDeleting {
      Menu {
        actionButtons
      } label: {
        Image(systemName: "ellipsis").frame(width: 44, height: 44)
      }
      .accessibilityLabel("Block actions")
    }
  }

  private func editBlock() {
    isRescheduling = false
    requestEditing()
  }

  private func rescheduleBlock() {
    isRescheduling = true
    requestEditing()
  }

  private func requestEditing() {
    guard !isDeleting, editingDraft == nil else { return }
    AppHaptics.tap()
    if isCreationRecord {
      onOpenSchedule()
      return
    }
    if isRecurring { choosingEditScope = true } else { beginEditing(scope: nil) }
  }

  private func beginEditing(scope: OccurrenceEditScope?) {
    let draft = BlockDraft.editing(
      block, on: completionDay, scope: scope, rescheduling: isRescheduling)
    editScope = scope
    withAnimation(.easeInOut(duration: 0.2)) { editingDraft = draft }
  }
}

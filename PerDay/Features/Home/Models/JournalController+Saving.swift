import Foundation

extension JournalController {
  func saveVoiceBlock(_ draft: BlockDraft) throws {
    guard drafts.isEmpty else {
      throw JournalEditError(
        message:
          "Found \(drafts.count) unfinished drafts; expected none before voice capture. Save or cancel your unfinished block first."
      )
    }
    try insertDraft(draft)
  }

  func saveDraft(_ id: UUID) {
    do {
      guard let draft = drafts.first(where: { $0.id == id }) else {
        throw JournalEditError(
          message:
            "Draft \(id) is unavailable; expected an active draft. Reopen the block and try again.")
      }
      try insertDraft(draft)
      drafts.removeAll { $0.id == id }
      feedback?.report(.success)
    } catch {
      reportFailure(error)
    }
  }

  private func insertDraft(_ draft: BlockDraft) throws {
    let block = try makeBlock(from: draft)
    repository.insert(block)
    try commitChanges()
    selectedDate = calendar.startOfDay(for: block.hasSchedule ? block.createdAt : block.noteDate)
  }

  func makeBlock(from draft: BlockDraft) throws -> NoteBlockModel {
    guard draft.canSave else {
      throw JournalEditError(
        message:
          "Draft \(draft.id) contains empty content; expected nonempty text and at least one named task in each task list."
      )
    }
    let block = NoteBlockModel(noteText: "", noteDate: draft.journalDate, kind: .basic)
    block.id = draft.id
    block.createdAt = draft.createdAt
    try block.applyComponents(draft.cleanedComponents)
    return block
  }

  func saveComponents(
    _ draft: BlockDraft, in block: NoteBlockModel, on day: Date, scope: OccurrenceEditScope?
  ) -> Bool {
    guard draft.canSave else { return false }
    do {
      let destination = try updateComponents(draft, in: block, on: day, scope: scope)
      try repository.save()
      selectedDate = calendar.startOfDay(for: destination)
      feedback?.report(.success)
      return true
    } catch {
      repository.rollback()
      reportFailure(error)
      return false
    }
  }

  private func updateComponents(
    _ draft: BlockDraft, in block: NoteBlockModel, on day: Date,
    scope: OccurrenceEditScope?
  ) throws -> Date {
    if let scope { return try saveOccurrence(draft, in: block, on: day, scope: scope) }
    let removingSchedule = block.hasSchedule && !draft.components.contains(where: \.definesSchedule)
    if removingSchedule { block.noteDate = calendar.startOfDay(for: block.createdAt) }
    try block.applyComponents(draft.cleanedComponents)
    return block.occurs(on: selectedDate, calendar: calendar) ? selectedDate : block.createdAt
  }
}

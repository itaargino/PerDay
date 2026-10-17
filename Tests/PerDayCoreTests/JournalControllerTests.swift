import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct JournalControllerTests {
  @Test func savingDraftPreservesIdentityAndRemovesEditor() {
    let repository = FakeJournalRepository()
    let journal = JournalController(repository: repository, today: TestDates.day)
    var draft = BlockDraft(kind: .text, day: TestDates.day)
    draft.text = "Remember this"
    journal.drafts = [draft]
    journal.saveDraft(draft.id)
    #expect(repository.blocks.first?.id == draft.id)
    #expect(repository.blocks.first?.createdAt == draft.createdAt)
    #expect(repository.blocks.first?.noteText == "Remember this")
    #expect(journal.drafts.isEmpty && journal.saveError == nil)
  }

  @Test func failedSaveKeepsDraftAndRollsBackExactlyOnce() {
    let repository = FakeJournalRepository()
    repository.rejectsSave = true
    let feedback = FakeJournalFeedback()
    let journal = JournalController(repository: repository, feedback: feedback)
    var draft = BlockDraft(kind: .text, day: TestDates.day)
    draft.text = "Do not lose this"
    journal.drafts = [draft]
    journal.saveDraft(draft.id)
    #expect(journal.drafts.first?.text == "Do not lose this")
    #expect(repository.blocks.isEmpty && repository.rollbackCount == 1)
    #expect(journal.saveError != nil && feedback.events == [.failure])
  }

  @Test func invalidOrMissingDraftDoesNotWrite() {
    let repository = FakeJournalRepository()
    let journal = JournalController(repository: repository)
    let draft = BlockDraft(kind: .text, day: TestDates.day)
    journal.drafts = [draft]
    journal.saveDraft(draft.id)
    #expect(journal.saveError?.contains(draft.id.uuidString) == true)
    journal.saveDraft(UUID())
    #expect(repository.saveCount == 0)
  }

  @Test func voiceCaptureRejectsUnfinishedDraft() {
    let repository = FakeJournalRepository()
    let journal = JournalController(repository: repository)
    let draft = BlockDraft(day: TestDates.day)
    journal.drafts = [draft]
    #expect(throws: JournalEditError.self) { try journal.saveVoiceBlock(draft) }
    #expect(repository.saveCount == 0)
  }

  @Test func voiceCaptureSavesWithoutAnEditor() throws {
    let repository = FakeJournalRepository()
    let journal = JournalController(repository: repository, calendar: TestDates.calendar)
    var draft = BlockDraft(kind: .text, day: TestDates.day)
    draft.text = "Captured"
    try journal.saveVoiceBlock(draft)
    #expect(repository.blocks.first?.noteText == "Captured")
    #expect(journal.selectedDate == TestDates.day)
  }

  @Test func draftHandoffNeverDuplicatesTimelineRow() throws {
    let journal = JournalController(
      repository: FakeJournalRepository(), calendar: TestDates.calendar)
    var draft = BlockDraft(kind: .text, day: TestDates.day)
    draft.text = "Entry"
    journal.drafts = [draft]
    journal.blocks = [try journal.makeBlock(from: draft)]
    #expect(journal.entries(on: TestDates.day).map(\.id) == [draft.id])
    #expect(journal.entries(on: TestDates.offset(1)).isEmpty)
  }

  @Test func deleteAndUndoRestoresBlockAndDay() {
    let block = TestDates.populatedBlock()
    let repository = FakeJournalRepository(blocks: [block])
    let journal = JournalController(repository: repository, blocks: [block], today: TestDates.day)
    journal.deleteEntry(.block(block))
    #expect(repository.blocks.isEmpty && journal.undoPresentationID != nil)
    journal.selectedDate = TestDates.offset(5)
    journal.undoDeletion()
    #expect(repository.blocks.first?.id == block.id)
    #expect(journal.selectedDate == journal.removalDay && journal.lastRemoved == nil)
  }

  @Test func failedDeleteDoesNotOfferUndo() {
    let block = TestDates.populatedBlock()
    let repository = FakeJournalRepository(blocks: [block])
    repository.rejectsSave = true
    let journal = JournalController(repository: repository)
    journal.deleteEntry(.block(block))
    #expect(repository.blocks.count == 1 && repository.rollbackCount == 1)
    #expect(journal.lastRemoved == nil && journal.undoPresentationID == nil)
  }

  @Test func failedUndoRetainsRetryOpportunity() {
    let block = TestDates.populatedBlock()
    let repository = FakeJournalRepository(blocks: [block])
    let journal = JournalController(repository: repository)
    journal.deleteEntry(.block(block))
    repository.rejectsSave = true
    journal.undoDeletion()
    #expect(journal.lastRemoved != nil && repository.blocks.isEmpty)
    repository.rejectsSave = false
    journal.undoDeletion()
    #expect(repository.blocks.count == 1 && journal.lastRemoved == nil)
  }

  @Test func draftDeleteAndUndoNeverTouchStorage() {
    let repository = FakeJournalRepository()
    let journal = JournalController(
      repository: repository, calendar: TestDates.calendar, today: TestDates.day)
    let draft = BlockDraft(day: TestDates.day)
    journal.drafts = [draft]
    journal.beginDeletion()
    #expect(journal.isDeleting)
    journal.deleteEntry(.draft(draft))
    #expect(journal.drafts.isEmpty)
    journal.undoDeletion()
    #expect(journal.drafts.first?.id == draft.id && repository.saveCount == 0)
  }
}

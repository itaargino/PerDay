import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct OccurrenceRevisionTests {
  private func repeatingBlock() throws -> NoteBlockModel {
    let block = NoteBlockModel(noteText: "", noteDate: TestDates.day, kind: .basic)
    var draft = BlockDraft(kind: .task, day: TestDates.day)
    draft.tasks = [TaskDraft(text: "Read")]
    draft.agendaDate = TestDates.day
    draft.agendaRecurrence = .daily
    block.createdAt = TestDates.offset(-1)
    try block.applyComponents(draft.components)
    return block
  }

  @Test func singleEditDetachesOccurrenceAndTransfersCompletion() throws {
    let block = try repeatingBlock()
    var components = block.components
    components[0].tasks[0].completedDays = [TestDates.offset(2)]
    try block.applyComponents(components)
    var draft = BlockDraft(block: block)
    draft.agendaDate = TestDates.offset(4)
    draft.agendaRecurrence = .never
    let repository = FakeJournalRepository(blocks: [block])
    let journal = JournalController(
      repository: repository, blocks: [block], calendar: TestDates.calendar)
    #expect(
      journal.saveComponents(draft, in: block, on: TestDates.offset(2), scope: .thisOccurrence))
    let detached = try #require(repository.blocks.last)
    #expect(block.excludedDays == [TestDates.offset(2)])
    #expect(detached.seriesID == block.id && detached.hidesCreationRecord)
    #expect(detached.components[0].tasks[0].completedDays == [TestDates.offset(4)])
  }

  @Test func futureEditTruncatesPastAndReplacesLaterSegments() throws {
    let block = try repeatingBlock()
    let later = try repeatingBlock()
    later.seriesID = block.id
    later.noteDate = TestDates.offset(10)
    var laterDraft = BlockDraft(block: later)
    laterDraft.agendaDate = TestDates.offset(10)
    try later.applyComponents(laterDraft.components)
    let repository = FakeJournalRepository(blocks: [block, later])
    let journal = JournalController(
      repository: repository, blocks: repository.blocks, calendar: TestDates.calendar)
    var draft = BlockDraft(block: block)
    draft.agendaDate = TestDates.offset(3)
    #expect(
      journal.saveComponents(draft, in: block, on: TestDates.offset(3), scope: .thisAndFuture))
    #expect(block.repeatUntil == TestDates.offset(2))
    #expect(repository.blocks.count == 2 && !repository.blocks.contains { $0.id == later.id })
    #expect(repository.blocks.last?.repeatUntil == nil)
  }

  @Test func earlierStartCannotRewritePast() throws {
    let block = try repeatingBlock()
    let repository = FakeJournalRepository(blocks: [block])
    let journal = JournalController(
      repository: repository, blocks: [block], calendar: TestDates.calendar)
    let draft = BlockDraft(block: block)
    #expect(
      !journal.saveComponents(draft, in: block, on: TestDates.offset(3), scope: .thisAndFuture))
    #expect(block.repeatUntil == nil && repository.blocks.count == 1)
    #expect(journal.saveError?.contains("expected") == true)
  }

  @Test func singleEditRejectsRecurrence() throws {
    let block = try repeatingBlock()
    let revision = OccurrenceRevision(
      draft: BlockDraft(block: block), anchor: TestDates.day,
      scope: .thisOccurrence, calendar: TestDates.calendar)
    #expect(throws: JournalEditError.self) { try revision.validate() }
  }

  @Test func skipRestoreAndTaskToggleArePerOccurrence() throws {
    let block = try repeatingBlock()
    let repository = FakeJournalRepository(blocks: [block])
    let journal = JournalController(
      repository: repository, blocks: [block], calendar: TestDates.calendar)
    journal.toggleSkippedOccurrence(in: block, on: TestDates.day)
    #expect(block.isSkipped(on: TestDates.day, calendar: TestDates.calendar))
    journal.toggleSkippedOccurrence(in: block, on: TestDates.day)
    let component = block.components[0]
    journal.toggleComponentTask(
      component.id, itemID: component.tasks[0].id, in: block, day: TestDates.day)
    #expect(
      block.components[0].tasks[0].isCompleted(on: TestDates.day, calendar: TestDates.calendar))
    #expect(
      !block.components[0].tasks[0].isCompleted(
        on: TestDates.offset(1), calendar: TestDates.calendar))
    journal.openSchedule(for: block)
    #expect(journal.selectedDate == TestDates.day)
  }
}

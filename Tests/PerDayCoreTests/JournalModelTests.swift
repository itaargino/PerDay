import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct JournalModelTests {
  let calendar: Calendar = TestDates.calendar

  @Test func legacyTaskKeepsIdentityAndCompletion() {
    let block = NoteBlockModel(noteText: "Study", noteDate: TestDates.day, kind: .task)
    block.completedDays = [TestDates.day]
    #expect(block.components.first?.tasks.first?.id == block.id)
    #expect(block.components.first?.tasks.first?.isCompleted(on: TestDates.day) == true)
    #expect(block.components.map(\.id) == block.components.map(\.id))
  }

  @Test func componentsRoundTripWithoutLosingHistory() throws {
    let block = NoteBlockModel(noteText: "", noteDate: TestDates.day)
    var component = JournalComponent(kind: .taskList)
    component.tasks = [TaskItem(text: "Study", completedDays: [TestDates.day])]
    try block.applyComponents([component])
    #expect(block.components.first?.id == component.id)
    #expect(block.components.first?.tasks.first?.completedDays == [TestDates.day])
    #expect(block.noteText == "Study")
  }

  @Test func completionIsIdempotentAndPerDay() {
    var task = TaskItem(text: "Read")
    task.setCompleted(true, on: TestDates.day, calendar: calendar)
    task.setCompleted(true, on: TestDates.day, calendar: calendar)
    #expect(task.completedDays.count == 1)
    #expect(!task.isCompleted(on: TestDates.offset(1), calendar: calendar))
    task.setCompleted(false, on: TestDates.day, calendar: calendar)
    #expect(task.completedDays.isEmpty)
  }

  @Test func weeklyScheduleHonorsSkippedExcludedAndEndDates() {
    let block = NoteBlockModel(noteText: "Study", noteDate: TestDates.day, kind: .task)
    block.recurrenceRaw = RepeatRule.weekly.rawValue
    #expect(block.isScheduled(on: TestDates.offset(7), calendar: calendar))
    #expect(!block.isScheduled(on: TestDates.offset(1), calendar: calendar))
    block.skippedDays = [TestDates.day]
    block.excludedDays = [TestDates.offset(7)]
    block.repeatUntil = TestDates.offset(14)
    #expect(block.nextOccurrence(calendar: calendar) == TestDates.offset(14))
    #expect(!block.isScheduled(on: TestDates.offset(21), calendar: calendar))
  }

  @Test func snapshotRestoresEveryPersistedField() {
    let original = TestDates.populatedBlock()
    let restored = BlockSnapshot(original).restore()
    #expect(restored.id == original.id)
    #expect(restored.noteText == original.noteText && restored.noteDate == original.noteDate)
    #expect(restored.createdAt == original.createdAt && restored.updatedAt == original.updatedAt)
    #expect(
      restored.kindRaw == original.kindRaw && restored.recurrenceRaw == original.recurrenceRaw)
    #expect(restored.weekdays == original.weekdays && restored.repeatUntil == original.repeatUntil)
    #expect(
      restored.skippedDays == original.skippedDays && restored.excludedDays == original.excludedDays
    )
    #expect(
      restored.seriesID == original.seriesID
        && restored.hidesCreationRecord == original.hidesCreationRecord)
    #expect(
      restored.completedDays == original.completedDays && restored.position == original.position)
    #expect(restored.taskItems.map(\.id) == original.taskItems.map(\.id))
    #expect(restored.componentData == original.componentData)
  }

  @Test func editingTaskPreservesCompletionHistory() {
    let task = TaskItem(text: "Original", completedDays: [TestDates.day])
    let updated = TaskDraft(id: task.id, text: "Edited").preservingHistory(in: [task])
    #expect(updated.id == task.id && updated.text == "Edited")
    #expect(updated.completedDays == task.completedDays)
    #expect(TaskDraft(text: "New").preservingHistory(in: []).completedDays.isEmpty)
  }

  @Test func draftCleansWhitespaceAndRejectsEmptyContent() {
    var draft = BlockDraft(kind: .task, day: TestDates.day)
    #expect(!draft.canSave)
    draft.tasks = [TaskDraft(text: "  Read \n"), TaskDraft(text: " ")]
    #expect(draft.canSave)
    #expect(draft.cleanedComponents.first?.tasks.map(\.text) == ["Read"])
  }

  @Test func calendarHandlesLeapMonthAndWeekStart() {
    let month = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
    let model = CalendarModel(calendar: calendar)
    #expect(model.days(in: month).count == 29)
    #expect(model.leadingDays(in: month) == 4)
    #expect(model.weekdaySymbols.count == 7)
  }
}

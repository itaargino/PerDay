import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct CalendarAndCompatibilityTests {
  @Test func selectedWeekdaysDeduplicateRejectInvalidValuesAndFallBackToAnchor() {
    var component = JournalComponent(kind: .recurrence)
    component.recurrence = .weekly
    component.recurrenceWeekdays = [0, 2, 2, 4, 8]
    #expect(
      component.selectedWeekdays(start: TestDates.day, calendar: TestDates.calendar) == [2, 4])
    component.recurrenceWeekdays = [0, 8]
    #expect(component.selectedWeekdays(start: TestDates.day, calendar: TestDates.calendar) == [3])
    component.recurrence = .daily
    #expect(component.selectedWeekdays(start: TestDates.day) == Array(1...7))
    #expect(component.recurrenceSummary(start: TestDates.day) == "Every day")
    component.recurrence = .never
    #expect(component.recurrenceSummary(start: TestDates.day) == "Does not repeat")
  }

  @Test func oldComponentJSONInheritsStoredWeekdays() throws {
    let block = NoteBlockModel(noteText: "", noteDate: TestDates.day)
    var recurrence = JournalComponent(kind: .recurrence)
    recurrence.recurrence = .weekly
    block.weekdays = [2, 6]
    block.componentData = try JSONEncoder().encode([recurrence])
    #expect(block.components.first?.recurrenceWeekdays == [2, 6])
    #expect(block.components.first?.id == recurrence.id)
  }

  @Test func undecodableComponentJSONFallsBackToLegacyText() {
    let block = NoteBlockModel(noteText: "Preserved", noteDate: TestDates.day)
    block.componentData = Data("invalid JSON".utf8)
    #expect(block.components.first?.text == "Preserved")
    #expect(block.components.map(\.id) == block.components.map(\.id))
  }

  @Test func scheduledBlockKeepsCreationReceiptUnlessHiddenOrExcluded() throws {
    let block = NoteBlockModel(noteText: "", noteDate: TestDates.offset(3), kind: .basic)
    block.createdAt = TestDates.day
    try block.applyComponents([JournalComponent(kind: .startDate, date: TestDates.offset(3))])
    #expect(block.isCreationRecord(on: TestDates.day, calendar: TestDates.calendar))
    #expect(block.occurs(on: TestDates.day, calendar: TestDates.calendar))
    block.hidesCreationRecord = true
    #expect(!block.isCreationRecord(on: TestDates.day, calendar: TestDates.calendar))
    block.hidesCreationRecord = false
    block.excludedDays = [TestDates.day]
    #expect(!block.occurs(on: TestDates.day, calendar: TestDates.calendar))
  }

  @Test func dailyAgendaPreservesClockTimeAcrossDaylightSaving() throws {
    var calendar = TestDates.calendar
    calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
    let start = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 9)))
    let nextDay = try #require(calendar.date(byAdding: .day, value: 1, to: start))
    let block = NoteBlockModel(noteText: "Meeting", noteDate: start, kind: .agenda)
    block.recurrenceRaw = "daily"
    let occurrence = try #require(block.agendaStart(on: nextDay, calendar: calendar))
    #expect(calendar.component(.hour, from: occurrence) == 9)
    #expect(occurrence.timeIntervalSince(start) == 23 * 60 * 60)
  }

  @Test func captureTimeUsesScheduleDayTimeZoneOffset() throws {
    var calendar = TestDates.calendar
    calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
    let summerDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 1)))
    let time = try VoiceCaptureDateParser(calendar: calendar).parse(
      "09:30", format: "HH:mm", relativeTo: summerDay)
    #expect(calendar.component(.hour, from: time) == 9)
    #expect(calendar.component(.day, from: time) == 1)
    #expect(calendar.component(.month, from: time) == 7)
  }

  @Test func draftConstructionUsesInjectedClock() {
    let draft = BlockDraft(
      kind: .agenda, day: TestDates.offset(2), now: TestDates.day, calendar: TestDates.calendar)
    #expect(draft.createdAt == TestDates.day)
    #expect(draft.scheduledDate(calendar: TestDates.calendar) == TestDates.offset(2))
    #expect(draft.kind == .agenda)
  }

  @Test func draftBridgesPreserveTaskHistoryAndRemoveRecurrence() throws {
    let block = NoteBlockModel(noteText: "Read", noteDate: TestDates.day, kind: .task)
    block.completedDays = [TestDates.day]
    var draft = BlockDraft(block: block)
    draft.tasks = [TaskDraft(id: block.id, text: "Read a chapter")]
    #expect(draft.components[0].tasks[0].completedDays == [TestDates.day])
    draft.agendaRecurrence = .weekly
    #expect(draft.components.contains { $0.definesSchedule })
    draft.agendaRecurrence = .never
    #expect(!draft.components.contains { $0.definesSchedule })
    draft.text = "Extra note"
    #expect(draft.text == "Extra note")
  }

  @Test func taskBlockCompletionSynchronizesWholeChecklist() {
    let block = NoteBlockModel(noteText: "Read", noteDate: TestDates.day, kind: .task)
    block.toggleCompletion(on: TestDates.day, calendar: TestDates.calendar)
    #expect(block.isCompleted(on: TestDates.day, calendar: TestDates.calendar))
    block.toggleTaskItem(block.checklist[0].id, on: TestDates.day, calendar: TestDates.calendar)
    #expect(!block.isCompleted(on: TestDates.day, calendar: TestDates.calendar))
    let tasks = [
      TaskItem(text: "A", completedDays: [TestDates.day]),
      TaskItem(text: "B", completedDays: [TestDates.day]),
    ]
    block.replaceTaskItems(tasks, calendar: TestDates.calendar)
    #expect(block.isCompleted(on: TestDates.day, calendar: TestDates.calendar))
    #expect(block.noteText == "A\nB")
  }
}

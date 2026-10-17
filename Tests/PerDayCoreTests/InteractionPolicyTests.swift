import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct InteractionPolicyTests {
  @Test func initialSilenceNeverFinishesBeforeTimeout() {
    var detector = SpeechActivityDetector()
    for tick in 1...100 { detector.sample(power: -60, elapsed: Double(tick) * 0.08) }
    #expect(!detector.hasEnded && !detector.isSpeaking)
    detector.sample(power: -60, elapsed: 60)
    #expect(detector.hasEnded)
  }

  @Test func sustainedSpeechThenSilenceFinishesCapture() {
    var detector = SpeechActivityDetector()
    for tick in 1...5 { detector.sample(power: -20, elapsed: Double(tick) * 0.08) }
    #expect(detector.isSpeaking && !detector.hasEnded)
    detector.sample(power: -60, elapsed: 2.3)
    #expect(detector.hasEnded && !detector.isSpeaking)
    #expect(detector.level >= CGFloat(Float(0.02)) && detector.level <= 1)
  }

  @Test func briefNoiseDoesNotSubmitCapture() {
    var detector = SpeechActivityDetector()
    detector.sample(power: -20, elapsed: 0.08)
    detector.sample(power: -60, elapsed: 4)
    #expect(!detector.hasEnded)
  }

  @Test func pageSwipeRespectsDistanceVelocityAndDirection() {
    let forward = DaySwipeDecision(travel: -110, predictedTravel: -110, width: 400)
    #expect(forward.shouldAdvance && forward.direction == 1 && forward.destinationOffset == -400)
    #expect(DaySwipeDecision(travel: 30, predictedTravel: 200, width: 400).shouldAdvance)
    #expect(!DaySwipeDecision(travel: 10, predictedTravel: 200, width: 400).shouldAdvance)
    #expect(!DaySwipeDecision(travel: 100, predictedTravel: 100, width: 0).shouldAdvance)
    #expect(
      DaySwipeDecision(travel: 110, predictedTravel: 110, width: 400).destinationOffset == 400)
  }
}

extension InteractionPolicyTests {
  @Test func multilineTasksPreserveLastEmptyRowAndNormalizeLineEndings() {
    let split = TaskLineSplit("First\r\n\rSecond\n \n")
    #expect(split.firstLine == "First")
    #expect(split.additionalTasks.map(\.text) == ["Second", ""])
    #expect(TaskLineSplit("Only one").additionalTasks.isEmpty)
    #expect(TaskLineSplit("").firstLine.isEmpty)
  }

  @Test func reschedulingAddsDateWithoutInventingTime() {
    let block = NoteBlockModel(noteText: "Note", noteDate: TestDates.day)
    let draft = BlockDraft.editing(block, on: TestDates.offset(2), scope: nil, rescheduling: true)
    #expect(draft.components.map(\.kind) == [.text, .startDate])
    #expect(draft.components.last?.date == TestDates.offset(2))
  }

  @Test func singleOccurrenceEditorRemovesRecurrenceAndKeepsTaskIdentity() throws {
    let block = NoteBlockModel(noteText: "Task", noteDate: TestDates.day, kind: .task)
    block.recurrenceRaw = "weekly"
    block.createdAt = TestDates.offset(-1)
    let draft = BlockDraft.editing(
      block, on: TestDates.offset(7), scope: .thisOccurrence,
      rescheduling: false, calendar: TestDates.calendar)
    #expect(draft.agendaRecurrence == .never)
    #expect(draft.journalDate == TestDates.offset(7))
    #expect(draft.tasks.first?.id == block.id)
  }

  @Test func futureOccurrenceEditorKeepsOriginalWeekdayAnchor() {
    let block = NoteBlockModel(noteText: "Task", noteDate: TestDates.day, kind: .task)
    block.recurrenceRaw = "weekly"
    block.createdAt = TestDates.offset(-1)
    let draft = BlockDraft.editing(
      block, on: TestDates.offset(7), scope: .thisAndFuture,
      rescheduling: false, calendar: TestDates.calendar)
    let recurrence = draft.components.first { $0.kind == .recurrence }
    #expect(
      recurrence?.recurrenceWeekdays == [
        TestDates.calendar.component(.weekday, from: TestDates.day)
      ])
  }
}

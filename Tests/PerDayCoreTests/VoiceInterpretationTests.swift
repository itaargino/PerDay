import Foundation
import Testing

@testable import PerDayCore

@Suite @MainActor
struct VoiceInterpretationTests {
  private func interpreter(_ generator: FakeVoiceBlockGenerator) -> VoiceBlockInterpreter {
    VoiceBlockInterpreter(
      generator: generator, calendar: TestDates.calendar, currentDate: { TestDates.day })
  }

  @Test func taskDoesNotProduceDuplicateText() async throws {
    let generator = FakeVoiceBlockGenerator()
    generator.result.text = "Buy milk"
    generator.result.textSource = "Buy milk"
    generator.result.tasks = [VoiceCapturedTask(text: "Buy milk", source: "Buy milk")]
    let draft = try await interpreter(generator).interpret(
      "  Buy milk  ", journalDay: TestDates.day)
    #expect(draft.components.map(\.kind) == [.taskList])
    #expect(generator.receivedTranscript == "Buy milk")
  }

  @Test func inventedEvidenceCannotCreateContent() async {
    let generator = FakeVoiceBlockGenerator()
    generator.result.tasks = [VoiceCapturedTask(text: "Delete notes", source: "Delete notes")]
    await #expect(throws: VoiceBlockError.self) {
      try await interpreter(generator).interpret("I felt happy", journalDay: TestDates.day)
    }
  }

  @Test func validationRunsBeforeExternalGeneration() async {
    let generator = FakeVoiceBlockGenerator()
    await #expect(throws: VoiceBlockError.self) {
      try await interpreter(generator).interpret(" \n", journalDay: TestDates.day)
    }
    await #expect(throws: VoiceBlockError.self) {
      try await interpreter(generator).interpret(
        String(repeating: "a", count: 6001), journalDay: TestDates.day)
    }
    #expect(generator.requestCount == 0)
  }

  @Test func unavailableModelDoesNotReceiveCapture() async {
    let generator = FakeVoiceBlockGenerator()
    generator.unavailableMessage = "Unavailable"
    await #expect(throws: VoiceBlockError.self) {
      try await interpreter(generator).interpret("Private note", journalDay: TestDates.day)
    }
    #expect(generator.requestCount == 0)
  }

  @Test func generatorFailurePropagates() async {
    let generator = FakeVoiceBlockGenerator()
    generator.failure = CancellationError()
    await #expect(throws: CancellationError.self) {
      try await interpreter(generator).interpret("Buy milk", journalDay: TestDates.day)
    }
  }

  @Test func explicitDateAndTimeAreCombined() async throws {
    let generator = FakeVoiceBlockGenerator()
    generator.result.text = "Dentist"
    generator.result.textSource = "Dentist"
    generator.result.startDate = "2026-10-15"
    generator.result.dateSource = "October 15"
    generator.result.startTime = "19:30"
    generator.result.timeSource = "7:30 PM"
    let draft = try await interpreter(generator).interpret(
      "Dentist October 15 at 7:30 PM", journalDay: TestDates.day)
    let parts = TestDates.calendar.dateComponents(
      [.year, .month, .day, .hour, .minute], from: draft.scheduledDate(calendar: TestDates.calendar)
    )
    #expect(parts == DateComponents(year: 2026, month: 10, day: 15, hour: 19, minute: 30))
  }

  @Test func unsupportedScheduleIsOmitted() async throws {
    let generator = FakeVoiceBlockGenerator()
    generator.result.text = "Happy"
    generator.result.textSource = "happy"
    generator.result.startTime = "12:00"
    generator.result.timeSource = "noon"
    generator.result.recurrence = .daily
    generator.result.recurrenceSource = "happy"
    let draft = try await interpreter(generator).interpret(
      "I felt happy", journalDay: TestDates.day)
    #expect(draft.components.map(\.kind) == [.text])
  }

  @Test func portugueseWeekdayUsesSpokenDay() async throws {
    let generator = FakeVoiceBlockGenerator()
    generator.result.tasks = [VoiceCapturedTask(text: "Estudar", source: "Estudar")]
    generator.result.recurrence = .weekly
    generator.result.recurrenceSource = "toda segunda"
    let draft = try await interpreter(generator).interpret(
      "Estudar toda segunda", journalDay: TestDates.day)
    #expect(draft.agendaRecurrence == .weekly)
    #expect(
      TestDates.calendar.component(
        .weekday, from: draft.scheduledDate(calendar: TestDates.calendar)) == 2)
  }

  @Test func sourceMatchingNormalizesWhitespaceButRespectsWordBoundaries() {
    let evidence = VoiceCaptureEvidence(calendar: TestDates.calendar, now: TestDates.day)
    #expect(evidence.hasSource("AÇÃO importante", in: "uma ação   importante hoje"))
    #expect(!evidence.hasSource("day", in: "today"))
    #expect(!evidence.hasSource("", in: "text"))
    #expect(!evidence.hasSource(nil, in: "text"))
    #expect(evidence.explicitWeekday(in: "segunda e terça") == nil)
    #expect(evidence.explicitWeekday(in: "na terça") == "terça")
  }

  @Test func weekdayResolutionUsesInjectedClockAndPreservesExplicitDates() {
    let evidence = VoiceCaptureEvidence(calendar: TestDates.calendar, now: TestDates.day)
    let today = TestDates.calendar.weekdaySymbols[
      TestDates.calendar.component(.weekday, from: TestDates.day) - 1]
    #expect(evidence.capturedWeekdayDate(today, journalDay: TestDates.day) == TestDates.day)
    #expect(
      evidence.capturedWeekdayDate("next \(today)", journalDay: TestDates.day)
        == TestDates.offset(7))
    #expect(
      evidence.capturedWeekdayDate("last \(today)", journalDay: TestDates.offset(30))
        == TestDates.offset(-7))
    #expect(evidence.capturedWeekdayDate("Monday October 15", journalDay: TestDates.day) == nil)
    #expect(evidence.capturedWeekdayDate(nil, journalDay: TestDates.day) == nil)
  }

  @Test func invalidDatesDescribeValueAndExpectedFormat() throws {
    let parser = VoiceCaptureDateParser(calendar: TestDates.calendar)
    do {
      _ = try parser.parse("2026-02-30", format: "yyyy-MM-dd", relativeTo: TestDates.day)
      Issue.record("Expected invalid date to be rejected")
    } catch {
      #expect(error.localizedDescription.contains("2026-02-30"))
      #expect(error.localizedDescription.contains("yyyy-MM-dd"))
    }
    #expect(throws: VoiceBlockError.self) {
      try parser.parse("25:99", format: "HH:mm", relativeTo: TestDates.day)
    }
  }
}

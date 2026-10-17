import Foundation

struct VoiceDraftComposer {
  let calendar: Calendar
  let now: Date
  private var evidence: VoiceCaptureEvidence { VoiceCaptureEvidence(calendar: calendar, now: now) }
  private var dateParser: VoiceCaptureDateParser { VoiceCaptureDateParser(calendar: calendar) }

  func compose(_ result: VoiceBlockResult, transcript: String, journalDay: Date) throws
    -> BlockDraft
  {
    var draft = BlockDraft(day: journalDay)
    let tasks = supportedTasks(result.tasks, transcript: transcript)
    draft.text = supportedText(result, tasks: tasks, transcript: transcript)
    if !tasks.isEmpty { draft.tasks = tasks }
    let scheduleDay = try appendDate(result, transcript: transcript, to: &draft)
    try appendTime(result, transcript: transcript, scheduleDay: scheduleDay, to: &draft)
    draft.agendaRecurrence = supportedRecurrence(result, transcript: transcript)
    guard !draft.components.isEmpty, draft.canSave else {
      throw VoiceBlockError(
        message:
          "Capture produced \(draft.components.count) valid components; expected at least one supported, nonempty component."
      )
    }
    return draft
  }

  private func supportedTasks(_ tasks: [VoiceCapturedTask], transcript: String) -> [TaskDraft] {
    tasks.compactMap { task in
      guard evidence.hasSource(task.source, in: transcript) else { return nil }
      let text = task.text.trimmingCharacters(in: .whitespacesAndNewlines)
      return text.isEmpty ? nil : TaskDraft(text: text)
    }
  }

  private func supportedText(_ result: VoiceBlockResult, tasks: [TaskDraft], transcript: String)
    -> String
  {
    let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedText = normalized(text)
    let duplicatesTask = tasks.contains { normalized($0.text) == normalizedText }
    // Do not store a second copy of a checklist or the full captured prompt.
    guard evidence.hasSource(result.textSource, in: transcript), !text.isEmpty, !duplicatesTask,
      tasks.isEmpty || normalizedText != normalized(transcript)
    else { return "" }
    return text
  }

  private func normalized(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }

  private func appendDate(
    _ result: VoiceBlockResult, transcript: String, to draft: inout BlockDraft
  ) throws -> Date {
    let source = evidence.hasSource(result.dateSource, in: transcript) ? result.dateSource : nil
    let weeklySource =
      supportedRecurrence(result, transcript: transcript) == .weekly ? result.recurrenceSource : nil
    let weekdaySource =
      source ?? (weeklySource != nil ? evidence.explicitWeekday(in: transcript) : nil)
    if let date = evidence.capturedWeekdayDate(
      weekdaySource ?? weeklySource, journalDay: draft.journalDate)
    {
      // Calendar weekday numbers are Sunday=1 through Saturday=7,
      // independent of the locale's first day of the week.
      draft.components.append(JournalComponent(kind: .startDate, date: date))
      return date
    }
    guard let raw = result.startDate, source != nil else { return draft.journalDate }
    let date = try dateParser.parse(raw, format: "yyyy-MM-dd", relativeTo: draft.journalDate)
    draft.components.append(JournalComponent(kind: .startDate, date: date))
    return date
  }

  private func appendTime(
    _ result: VoiceBlockResult, transcript: String, scheduleDay: Date, to draft: inout BlockDraft
  ) throws {
    guard let raw = result.startTime, evidence.hasSource(result.timeSource, in: transcript) else {
      return
    }
    let time = try dateParser.parse(raw, format: "HH:mm", relativeTo: scheduleDay)
    draft.components.append(JournalComponent(kind: .startTime, date: time))
  }

  private func supportedRecurrence(_ result: VoiceBlockResult, transcript: String) -> RepeatRule {
    guard let rule = result.recurrence, evidence.hasSource(result.recurrenceSource, in: transcript),
      evidence.hasExplicitRecurrence(rule, in: transcript)
    else { return .never }
    return rule == .daily ? .daily : .weekly
  }
}

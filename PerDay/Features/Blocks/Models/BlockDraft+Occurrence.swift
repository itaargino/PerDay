import Foundation

extension BlockDraft {
  /// Preserves the chosen series scope before showing the component editor.
  /// Example: `BlockDraft.editing(block, on: today, scope: .thisOccurrence, rescheduling: false)`.
  static func editing(
    _ block: NoteBlockModel, on day: Date, scope: OccurrenceEditScope?,
    rescheduling: Bool, calendar: Calendar = .current
  ) -> BlockDraft {
    var draft = BlockDraft(block: block)
    if let scope {
      draft.configureOccurrence(block, day: day, scope: scope, calendar: calendar)
    } else if rescheduling && !draft.components.contains(where: { $0.kind == .startDate }) {
      draft.components.append(JournalComponent(kind: .startDate, date: day))
    }
    return draft
  }

  private mutating func configureOccurrence(
    _ block: NoteBlockModel, day: Date,
    scope: OccurrenceEditScope, calendar: Calendar
  ) {
    let day =
      block.isCreationRecord(on: day, calendar: calendar)
      ? (block.nextOccurrence(calendar: calendar) ?? block.componentStart(calendar: calendar)) : day
    journalDate = day
    if let index = components.firstIndex(where: { $0.kind == .startDate }) {
      components[index].date = day
    } else {
      components.append(JournalComponent(kind: .startDate, date: day))
    }
    guard scope != .thisOccurrence else {
      components.removeAll { $0.kind == .recurrence }
      return
    }
    guard let index = components.firstIndex(where: { $0.kind == .recurrence }) else { return }
    components[index].recurrenceWeekdays = components[index].selectedWeekdays(
      start: block.componentStart(calendar: calendar), calendar: calendar)
  }
}

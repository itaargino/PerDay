import Foundation

struct OccurrenceRevision {
  let draft: BlockDraft
  let anchor: Date
  let scope: OccurrenceEditScope
  let calendar: Calendar
  var newStart: Date { calendar.startOfDay(for: draft.scheduledDate(calendar: calendar)) }

  func validate() throws {
    guard scope != .thisAndFuture || newStart >= anchor else {
      throw JournalEditError(
        message:
          "Start date \(newStart) precedes \(anchor); expected a date on or after this occurrence to preserve earlier entries."
      )
    }
    guard scope != .thisOccurrence || draft.agendaRecurrence == .never else {
      throw JournalEditError(
        message:
          "Single-occurrence edit has recurrence '\(draft.agendaRecurrence.rawValue)'; expected 'never'. Choose This and future occurrences to change repetition."
      )
    }
  }

  func continuation(of original: NoteBlockModel, related: [NoteBlockModel]) throws -> NoteBlockModel
  {
    let block = NoteBlockModel(
      noteText: "", noteDate: draft.scheduledDate(calendar: calendar), kind: .basic)
    block.createdAt = original.createdAt
    block.seriesID = original.seriesID ?? original.id
    block.hidesCreationRecord = true
    try block.applyComponents(revisedComponents(related: related))
    if scope == .thisAndFuture { transferSchedule(to: block, related: related) }
    return block
  }

  private func revisedComponents(related: [NoteBlockModel]) -> [JournalComponent] {
    draft.cleanedComponents.map { component in
      var revised = component
      revised.tasks = component.tasks.map { revisedTask($0, related: related) }
      return revised
    }
  }

  private func revisedTask(_ task: TaskItem, related: [NoteBlockModel]) -> TaskItem {
    var revised = task
    if scope == .thisOccurrence {
      revised.completedDays = task.isCompleted(on: anchor, calendar: calendar) ? [newStart] : []
      return revised
    }
    let history = related.flatMap(\.components).flatMap(\.tasks)
      .filter { $0.id == task.id }.flatMap(\.completedDays)
    revised.completedDays = futureDays(history)
    return revised
  }

  private func transferSchedule(to block: NoteBlockModel, related: [NoteBlockModel]) {
    let recurring = related.filter { $0.componentRecurrence != .never }
    block.repeatUntil =
      recurring.contains { $0.repeatUntil == nil }
      ? nil : recurring.compactMap(\.repeatUntil).max()
    block.skippedDays = futureDays(related.flatMap(\.skippedDays))
  }

  private func futureDays(_ days: [Date]) -> [Date] {
    Array(Set(days.filter { calendar.startOfDay(for: $0) >= anchor })).sorted()
  }
}

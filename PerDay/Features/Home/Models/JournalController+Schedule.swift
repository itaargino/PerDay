import Foundation

extension JournalController {
  func openSchedule(for block: NoteBlockModel) {
    let identity = block.seriesID ?? block.id
    let next = blocks.filter { ($0.seriesID ?? $0.id) == identity }
      .compactMap { $0.nextOccurrence(calendar: calendar) }.min()
    guard let next else {
      saveError = "This block has no remaining scheduled occurrences."
      return
    }
    selectedDate = calendar.startOfDay(for: next)
    feedback?.report(.tap)
  }

  func toggleSkippedOccurrence(in block: NoteBlockModel, on day: Date) {
    guard block.componentRecurrence != .never,
      !block.isCreationRecord(on: day, calendar: calendar)
    else { return }
    if block.isSkipped(on: day, calendar: calendar) {
      block.skippedDays.removeAll { calendar.isDate($0, inSameDayAs: day) }
    } else {
      block.skippedDays.append(calendar.startOfDay(for: day))
    }
    block.updatedAt = .now
    do {
      try commitChanges()
      feedback?.report(.tap)
    } catch {
      reportFailure(error)
    }
  }

  func toggleComponentTask(_ componentID: UUID, itemID: UUID, in block: NoteBlockModel, day: Date) {
    guard block.isScheduled(on: day, calendar: calendar) else { return }
    var components = block.components
    guard let index = components.firstIndex(where: { $0.id == componentID }),
      let itemIndex = components[index].tasks.firstIndex(where: { $0.id == itemID })
    else { return }
    let completed = components[index].tasks[itemIndex].isCompleted(on: day, calendar: calendar)
    components[index].tasks[itemIndex].setCompleted(!completed, on: day, calendar: calendar)
    persistTaskCompletion(components, in: block)
  }

  private func persistTaskCompletion(_ components: [JournalComponent], in block: NoteBlockModel) {
    do {
      try block.applyComponents(components)
      try repository.save()
      feedback?.report(.selection)
    } catch {
      repository.rollback()
      reportFailure(error)
    }
  }
}

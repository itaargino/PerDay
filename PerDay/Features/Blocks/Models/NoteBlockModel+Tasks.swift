import Foundation

extension NoteBlockModel {
  func isCompleted(on day: Date, calendar: Calendar = .current) -> Bool {
    completedDays.contains { calendar.isDate($0, inSameDayAs: day) }
  }

  func toggleCompletion(on day: Date, calendar: Calendar = .current) {
    guard kind == .task, isScheduled(on: day, calendar: calendar) else { return }
    let complete = !isCompleted(on: day, calendar: calendar)
    taskItems = checklist.map { item in
      var item = item
      item.setCompleted(complete, on: day, calendar: calendar)
      return item
    }
    syncCompletion(on: day, calendar: calendar)
  }

  func toggleTaskItem(_ itemID: UUID, on day: Date, calendar: Calendar = .current) {
    guard kind == .task, isScheduled(on: day, calendar: calendar) else { return }
    var items = checklist
    guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
    items[index].setCompleted(
      !items[index].isCompleted(on: day, calendar: calendar), on: day, calendar: calendar)
    taskItems = items
    syncCompletion(on: day, calendar: calendar)
  }

  /// Preserve item identities and occurrence history when a checklist is edited.
  func replaceTaskItems(_ items: [TaskItem], calendar: Calendar = .current) {
    guard kind == .task, !items.isEmpty else { return }
    taskItems = items
    noteText = items.map(\.text).joined(separator: "\n")
    let candidateDays = Set(items.flatMap(\.completedDays).map { calendar.startOfDay(for: $0) })
    completedDays = candidateDays.filter { day in
      items.allSatisfy { $0.isCompleted(on: day, calendar: calendar) }
    }.sorted()
    updatedAt = .now
  }

  private func syncCompletion(on day: Date, calendar: Calendar) {
    completedDays.removeAll { calendar.isDate($0, inSameDayAs: day) }
    if !taskItems.isEmpty && taskItems.allSatisfy({ $0.isCompleted(on: day, calendar: calendar) }) {
      completedDays.append(calendar.startOfDay(for: day))
    }
    updatedAt = .now
  }
}

import Foundation

extension NoteBlockModel {
  /// Older stores are adapted in memory, without deleting or rewriting notes.
  var components: [JournalComponent] {
    if let componentData,
      let decoded = try? JSONDecoder().decode([JournalComponent].self, from: componentData)
    {
      return decoded.map { value in
        var value = value
        if value.kind == .recurrence && value.recurrenceWeekdays == nil && !weekdays.isEmpty {
          value.recurrenceWeekdays = weekdays
        }
        return value
      }
    }
    return legacyComponents()
  }

  private func legacyComponents() -> [JournalComponent] {
    var values: [JournalComponent] = [legacyContent()]
    if kind == .agenda {
      values.append(JournalComponent(kind: .startDate, date: noteDate))
      values.append(JournalComponent(kind: .startTime, date: noteDate))
    }
    if recurrence != .never { values.append(legacyRecurrence()) }
    // Legacy component identities must remain stable across SwiftUI renders.
    for index in values.indices {
      var bytes = id.uuid
      bytes.15 ^= UInt8(index + 1)
      values[index].id = UUID(uuid: bytes)
    }
    return values
  }

  private func legacyContent() -> JournalComponent {
    var component = JournalComponent(kind: kind == .task ? .taskList : .text)
    if kind == .task { component.tasks = checklist } else { component.text = noteText }
    return component
  }

  private func legacyRecurrence() -> JournalComponent {
    var component = JournalComponent(kind: .recurrence)
    component.recurrence = recurrence
    component.recurrenceWeekdays = weekdays.isEmpty ? nil : weekdays
    return component
  }

  var hasSchedule: Bool {
    components.contains(where: \.definesSchedule)
  }

  var componentRecurrence: RepeatRule {
    components.first(where: { $0.kind == .recurrence })?.recurrence ?? .never
  }

  /// Date and time components combine in the user's calendar, preserving wall
  /// clock time across DST. Recurrence applies to this entire parent block.
  func componentStart(calendar: Calendar = .current) -> Date {
    let date = components.first(where: { $0.kind == .startDate })?.date ?? noteDate
    guard let time = components.first(where: { $0.kind == .startTime })?.date else {
      return calendar.startOfDay(for: date)
    }
    let parts = calendar.dateComponents([.hour, .minute], from: time)
    return calendar.date(
      bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0,
      of: date, matchingPolicy: .nextTimePreservingSmallerComponents,
      repeatedTimePolicy: .first, direction: .forward) ?? date
  }

  func applyComponents(_ values: [JournalComponent]) throws {
    // Encode before mutating the model so a failed encode leaves it intact.
    let encodedComponents = try JSONEncoder().encode(values)
    componentData = encodedComponents
    noteText = values.flatMap { value -> [String] in
      if value.kind == .text { return [value.text] }
      if value.kind == .taskList { return value.tasks.map(\.text) }
      return []
    }.joined(separator: "\n")
    recurrenceRaw = componentRecurrence.rawValue
    weekdays =
      values.first(where: { $0.kind == .recurrence })?.selectedWeekdays(start: componentStart())
      ?? []
    taskItems = values.filter { $0.kind == .taskList }.flatMap(\.tasks)
    if hasSchedule { noteDate = componentStart() }
    updatedAt = .now
  }
}

import Foundation

extension NoteBlockModel {
  /// The journal includes both real occurrences and a creation-day receipt.
  func occurs(on day: Date, calendar: Calendar = .current) -> Bool {
    isPlanned(on: day, calendar: calendar) || isCreationRecord(on: day, calendar: calendar)
  }

  func isCreationRecord(on day: Date, calendar: Calendar = .current) -> Bool {
    guard !hidesCreationRecord,
      !excludedDays.contains(where: { calendar.isDate($0, inSameDayAs: day) }),
      calendar.isDate(day, inSameDayAs: createdAt),
      !isPlanned(on: day, calendar: calendar)
    else { return false }
    let start = componentData == nil ? noteDate : componentStart(calendar: calendar)
    return hasSchedule || kind == .agenda
      || calendar.startOfDay(for: start) > calendar.startOfDay(for: createdAt)
  }

  func isSkipped(on day: Date, calendar: Calendar = .current) -> Bool {
    skippedDays.contains { calendar.isDate($0, inSameDayAs: day) }
  }

  func isScheduled(on day: Date, calendar: Calendar = .current) -> Bool {
    isPlanned(on: day, calendar: calendar) && !isSkipped(on: day, calendar: calendar)
  }

  func nextOccurrence(calendar: Calendar = .current) -> Date? {
    let start = componentData == nil ? noteDate : componentStart(calendar: calendar)
    for offset in 0...((skippedDays.count + excludedDays.count) * 7 + 7) {
      guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
      if isScheduled(on: day, calendar: calendar) { return day }
    }
    return nil
  }

  private func isPlanned(on day: Date, calendar: Calendar = .current) -> Bool {
    guard !excludedDays.contains(where: { calendar.isDate($0, inSameDayAs: day) }) else {
      return false
    }
    let day = calendar.startOfDay(for: day)
    let start = calendar.startOfDay(
      for: componentData == nil ? noteDate : componentStart(calendar: calendar))
    guard day >= start else { return false }
    if let repeatUntil, day > calendar.startOfDay(for: repeatUntil) { return false }
    guard componentData != nil || kind == .task || kind == .agenda else { return day == start }
    switch componentData == nil ? recurrence : componentRecurrence {
    case .never: return day == start
    case .daily: return true
    case .weekly:
      return scheduledWeekdays(calendar: calendar).contains(calendar.component(.weekday, from: day))
    }
  }

  private func scheduledWeekdays(calendar: Calendar) -> [Int] {
    guard componentData != nil,
      let component = components.first(where: { $0.kind == .recurrence })
    else {
      return weekdays.isEmpty ? [calendar.component(.weekday, from: noteDate)] : weekdays
    }
    return component.selectedWeekdays(start: componentStart(calendar: calendar), calendar: calendar)
  }

  /// Recurrences reuse the local clock time of noteDate, using calendar
  /// arithmetic instead of adding 24 hours across daylight-saving changes.
  func agendaStart(on day: Date, calendar: Calendar = .current) -> Date? {
    guard kind == .agenda, isScheduled(on: day, calendar: calendar) else { return nil }
    let time = calendar.dateComponents([.hour, .minute, .second], from: noteDate)
    return calendar.date(
      bySettingHour: time.hour ?? 0, minute: time.minute ?? 0,
      second: time.second ?? 0, of: day,
      matchingPolicy: .nextTimePreservingSmallerComponents,
      repeatedTimePolicy: .first, direction: .forward)
  }

}

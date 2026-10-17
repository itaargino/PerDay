import Foundation

enum ComponentKind: String, Codable, CaseIterable, Identifiable {
  case text, startDate, startTime, recurrence, taskList
  var id: String { rawValue }
  var title: String {
    switch self {
    case .text: "Text"
    case .startDate: "Start date"
    case .startTime: "Start time"
    case .recurrence: "Recurrence"
    case .taskList: "Task list"
    }
  }
  var symbol: String {
    switch self {
    case .text: "text.alignleft"
    case .startDate: "calendar"
    case .startTime: "clock"
    case .recurrence: "repeat"
    case .taskList: "checklist"
    }
  }
  var isUnique: Bool { self != .text && self != .taskList }
}

/// A value component keeps its identity and task occurrence history when moved.
struct JournalComponent: Codable, Identifiable {
  var id: UUID = UUID()
  var kind: ComponentKind
  var text: String = ""
  var date: Date = .now
  var recurrence: RepeatRule = .never
  // Optional so component JSON saved before weekday selection still decodes.
  var recurrenceWeekdays: [Int]? = nil
  var tasks: [TaskItem] = []

  init(kind: ComponentKind, date: Date = .now) {
    self.kind = kind
    self.date = date
    if kind == .taskList { tasks = [TaskItem(text: "")] }
  }
}

extension JournalComponent {
  func selectedWeekdays(start: Date, calendar: Calendar = .current) -> [Int] {
    switch recurrence {
    case .never: return []
    case .daily: return Array(1...7)
    case .weekly:
      let valid = Set((recurrenceWeekdays ?? []).filter { (1...7).contains($0) })
      return valid.isEmpty ? [calendar.component(.weekday, from: start)] : valid.sorted()
    }
  }

  func recurrenceSummary(start: Date, calendar: Calendar = .current) -> String {
    let days = selectedWeekdays(start: start, calendar: calendar)
    if days.isEmpty { return "Does not repeat" }
    if days.count == 7 { return "Every day" }
    let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    let ordered = Array(1...7)
    return "Every week: "
      + ordered.filter { days.contains($0) }.map { names[$0 - 1] }.joined(separator: ", ")
  }
}

extension JournalComponent {
  var definesSchedule: Bool {
    kind == .startDate || kind == .startTime || (kind == .recurrence && recurrence != .never)
  }
}

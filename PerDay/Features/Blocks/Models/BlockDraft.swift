import Foundation

struct BlockDraft: Identifiable {
  let id: UUID
  let createdAt: Date
  var journalDate: Date
  var components: [JournalComponent]

  init(kind: BlockKind = .basic, day: Date, now: Date = .now, calendar: Calendar = .current) {
    id = UUID()
    createdAt = now
    journalDate = day
    let time = calendar.dateComponents([.hour, .minute], from: createdAt)
    let start =
      calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day)
      ?? day
    switch kind {
    case .basic: components = []
    case .text: components = [JournalComponent(kind: .text)]
    case .task: components = [JournalComponent(kind: .taskList)]
    case .agenda:
      components = [
        JournalComponent(kind: .text), JournalComponent(kind: .startDate, date: start),
        JournalComponent(kind: .startTime, date: start),
      ]
    }
  }

  init(block: NoteBlockModel) {
    id = block.id
    createdAt = block.createdAt
    journalDate = block.noteDate
    components = block.components
  }

  var kind: BlockKind {
    if components.contains(where: { $0.kind == .startDate || $0.kind == .startTime }) {
      return .agenda
    }
    if components.contains(where: { $0.kind == .taskList }) { return .task }
    return components.isEmpty ? .basic : .text
  }

  // Bridges keep Intelligent Capture and existing task editors compatible.
  var text: String {
    get { components.first(where: { $0.kind == .text })?.text ?? "" }
    set {
      if let index = components.firstIndex(where: { $0.kind == .text }) {
        components[index].text = newValue
      } else if !newValue.isEmpty {
        var value = JournalComponent(kind: .text)
        value.text = newValue
        components.insert(value, at: 0)
      }
    }
  }
  var tasks: [TaskDraft] {
    get {
      components.first(where: { $0.kind == .taskList })?.tasks.map {
        TaskDraft(id: $0.id, text: $0.text)
      } ?? []
    }
    set {
      if let index = components.firstIndex(where: { $0.kind == .taskList }) {
        let previous = components[index].tasks
        components[index].tasks = newValue.map { $0.preservingHistory(in: previous) }
      } else if !newValue.isEmpty {
        var value = JournalComponent(kind: .taskList)
        value.tasks = newValue.map { TaskItem(id: $0.id, text: $0.text) }
        components.append(value)
      }
    }
  }
  func scheduledDate(calendar: Calendar = .current) -> Date {
    let day = components.first(where: { $0.kind == .startDate })?.date ?? journalDate
    let time = components.first(where: { $0.kind == .startTime })?.date ?? day
    let parts = calendar.dateComponents([.hour, .minute], from: time)
    return calendar.date(
      bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: day) ?? day
  }

  var agendaDate: Date {
    get { scheduledDate() }
    set {
      for kind in [ComponentKind.startDate, .startTime] {
        if let index = components.firstIndex(where: { $0.kind == kind }) {
          components[index].date = newValue
        } else {
          components.append(JournalComponent(kind: kind, date: newValue))
        }
      }
    }
  }
  var agendaRecurrence: RepeatRule {
    get { components.first(where: { $0.kind == .recurrence })?.recurrence ?? .never }
    set {
      if newValue == .never {
        components.removeAll { $0.kind == .recurrence }
      } else if let index = components.firstIndex(where: { $0.kind == .recurrence }) {
        components[index].recurrence = newValue
      } else if newValue != .never {
        var value = JournalComponent(kind: .recurrence)
        value.recurrence = newValue
        components.append(value)
      }
    }
  }
  var canSave: Bool {
    components.allSatisfy { component in
      switch component.kind {
      case .text: return !component.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      case .taskList:
        return component.tasks.contains {
          !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
      default: return true
      }
    }
  }
  var cleanedComponents: [JournalComponent] {
    components.map { value in
      var value = value
      value.text = value.text.trimmingCharacters(in: .whitespacesAndNewlines)
      value.tasks = value.tasks.compactMap { item in
        var item = item
        item.text = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return item.text.isEmpty ? nil : item
      }
      return value
    }
  }
}

import Foundation
import SwiftData

// Keep the existing model and property names so previous notes remain in the store.
@Model
final class NoteBlockModel {
  var noteText: String
  var noteDate: Date
  var id: UUID = UUID()
  var createdAt: Date = Date.now
  var updatedAt: Date = Date.now
  var kindRaw: String = "text"
  var recurrenceRaw: String = "never"
  var weekdays: [Int] = []
  var repeatUntil: Date?
  var skippedDays: [Date] = []
  var excludedDays: [Date] = []
  var seriesID: UUID? = nil
  var hidesCreationRecord: Bool = false
  var completedDays: [Date] = []
  var taskItems: [TaskItem] = []
  var position: Double = 0
  var componentData: Data? = nil

  init(noteText: String, noteDate: Date, kind: BlockKind = .text) {
    self.noteText = noteText
    self.noteDate = noteDate
    self.kindRaw = kind.rawValue
  }

  var kind: BlockKind { BlockKind(rawValue: kindRaw) ?? .text }
  var recurrence: RepeatRule { RepeatRule(rawValue: recurrenceRaw) ?? .never }

  // Older task blocks become one checklist item without losing their text or status.
  var checklist: [TaskItem] {
    guard kind == .task else { return [] }
    return taskItems.isEmpty
      ? [TaskItem(id: id, text: noteText, completedDays: completedDays)]
      : taskItems
  }

}

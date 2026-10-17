import Foundation

/// Value copy used by Undo after SwiftData has deleted the original object.
struct BlockSnapshot {
  let id: UUID
  let text: String
  let date: Date
  let createdAt: Date
  let updatedAt: Date
  let kindRaw: String
  let recurrenceRaw: String
  let weekdays: [Int]
  let repeatUntil: Date?
  let skippedDays: [Date]
  let excludedDays: [Date]
  let seriesID: UUID?
  let hidesCreationRecord: Bool
  let completedDays: [Date]
  let taskItems: [TaskItem]
  let position: Double
  let componentData: Data?

  init(_ block: NoteBlockModel) {
    id = block.id
    text = block.noteText
    date = block.noteDate
    createdAt = block.createdAt
    updatedAt = block.updatedAt
    kindRaw = block.kindRaw
    recurrenceRaw = block.recurrenceRaw
    weekdays = block.weekdays
    repeatUntil = block.repeatUntil
    skippedDays = block.skippedDays
    excludedDays = block.excludedDays
    seriesID = block.seriesID
    hidesCreationRecord = block.hidesCreationRecord
    completedDays = block.completedDays
    taskItems = block.taskItems
    position = block.position
    componentData = block.componentData
  }

  func restore() -> NoteBlockModel {
    let block = NoteBlockModel(noteText: text, noteDate: date)
    block.id = id
    block.createdAt = createdAt
    block.updatedAt = updatedAt
    block.kindRaw = kindRaw
    block.recurrenceRaw = recurrenceRaw
    block.weekdays = weekdays
    block.repeatUntil = repeatUntil
    block.skippedDays = skippedDays
    block.excludedDays = excludedDays
    block.seriesID = seriesID
    block.hidesCreationRecord = hidesCreationRecord
    block.completedDays = completedDays
    block.taskItems = taskItems
    block.position = position
    block.componentData = componentData
    return block
  }
}

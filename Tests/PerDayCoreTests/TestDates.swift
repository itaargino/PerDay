import Foundation

@testable import PerDayCore

@MainActor
enum TestDates {
  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    calendar.firstWeekday = 1
    calendar.locale = Locale(identifier: "en_US_POSIX")
    return calendar
  }
  static let day: Date = Date(timeIntervalSince1970: 1_728_950_400)

  static func offset(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: days, to: day)!
  }

  static func populatedBlock() -> NoteBlockModel {
    let block = NoteBlockModel(noteText: "Original", noteDate: day, kind: .agenda)
    block.createdAt = offset(-1)
    block.updatedAt = offset(1)
    block.recurrenceRaw = "weekly"
    block.weekdays = [2, 4]
    block.repeatUntil = offset(30)
    block.skippedDays = [offset(7)]
    block.excludedDays = [offset(14)]
    block.seriesID = UUID()
    block.hidesCreationRecord = true
    block.completedDays = [day]
    block.taskItems = [TaskItem(text: "Read", completedDays: [day])]
    block.position = 42
    block.componentData = Data("[]".utf8)
    return block
  }
}

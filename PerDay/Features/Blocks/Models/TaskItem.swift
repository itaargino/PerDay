import Foundation

struct TaskItem: Codable, Identifiable {
  var id: UUID = UUID()
  var text: String
  var completedDays: [Date] = []

  func isCompleted(on day: Date, calendar: Calendar = .current) -> Bool {
    completedDays.contains { calendar.isDate($0, inSameDayAs: day) }
  }

  mutating func setCompleted(_ completed: Bool, on day: Date, calendar: Calendar = .current) {
    completedDays.removeAll { calendar.isDate($0, inSameDayAs: day) }
    if completed { completedDays.append(calendar.startOfDay(for: day)) }
  }
}

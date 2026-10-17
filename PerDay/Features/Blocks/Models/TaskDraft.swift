import Foundation

struct TaskDraft: Identifiable {
  var id: UUID = UUID()
  var text: String = ""

  func preservingHistory(in previous: [TaskItem]) -> TaskItem {
    var item = previous.first { $0.id == id } ?? TaskItem(id: id, text: text)
    item.text = text
    return item
  }
}

import Foundation

enum BlockKind: String, Codable, CaseIterable, Identifiable {
  case basic, text, task, agenda
  var id: String { rawValue }
  var title: String {
    switch self {
    case .basic: "Block"
    case .text: "Text"
    case .task: "Task"
    case .agenda: "Agenda"
    }
  }
  var symbol: String {
    switch self {
    case .basic: "square.stack"
    case .text: "text.alignleft"
    case .task: "checkmark.circle"
    case .agenda: "calendar"
    }
  }
}

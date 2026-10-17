import Foundation

struct TaskLineSplit {
  let lines: [String]

  init(_ text: String) {
    lines = text.replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
  }

  var firstLine: String { lines.first ?? "" }
  var additionalTasks: [TaskDraft] {
    lines.dropFirst().enumerated().compactMap { entry in
      let isLast = entry.offset == lines.count - 2
      let isEmpty = entry.element.trimmingCharacters(in: .whitespaces).isEmpty
      return isEmpty && !isLast ? nil : TaskDraft(text: entry.element)
    }
  }
}

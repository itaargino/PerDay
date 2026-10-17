import Foundation

enum JournalEntry: Identifiable {
  case draft(BlockDraft)
  case block(NoteBlockModel)

  var id: UUID {
    switch self {
    case .draft(let draft): draft.id
    case .block(let block): block.id
    }
  }

  var deletionLabel: String {
    switch self {
    case .draft(let draft): return "Delete \(draft.kind.title.lowercased()) draft"
    case .block(let block):
      return "Delete \(block.kind.title.lowercased()) block: \(block.noteText)"
    }
  }

  var deletionHint: String {
    if case .block(let block) = self, block.componentRecurrence != .never {
      return "Removes the entire repeating series. Undo is available afterward."
    }
    return "Removes this block. Undo is available afterward."
  }

  var createdAt: Date {
    switch self {
    case .draft(let draft): draft.createdAt
    case .block(let block): block.createdAt
    }
  }

  func timestamp(on day: Date) -> Date { createdAt }
  var timestampLabel: String { "Created at" }

}

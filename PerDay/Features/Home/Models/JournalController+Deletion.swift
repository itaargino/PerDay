import Foundation

extension JournalController {
  func beginDeletion() {
    guard !timeline.isEmpty else { return }
    isDeleting = true
  }

  func deleteEntry(_ entry: JournalEntry) {
    do {
      lastRemoved = try removeEntry(entry)
      removalDay = selectedDate
      undoPresentationID = UUID()
      feedback?.report(.success)
    } catch {
      reportFailure(error)
    }
  }

  private func removeEntry(_ entry: JournalEntry) throws -> RemovedEntry {
    switch entry {
    case .draft(let draft):
      drafts.removeAll { $0.id == draft.id }
      return .draft(draft)
    case .block(let block):
      let snapshot = BlockSnapshot(block)
      repository.delete(block)
      try commitChanges()
      return .block(snapshot)
    }
  }

  func undoDeletion() {
    guard let lastRemoved else { return }
    do {
      try restoreEntry(lastRemoved)
      selectedDate = removalDay
      self.lastRemoved = nil
      undoPresentationID = nil
      feedback?.report(.success)
    } catch {
      reportFailure(error)
    }
  }

  private func restoreEntry(_ entry: RemovedEntry) throws {
    switch entry {
    case .draft(let draft): drafts.append(draft)
    case .block(let snapshot):
      repository.insert(snapshot.restore())
      try commitChanges()
    }
  }
}

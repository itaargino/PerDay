import Foundation

extension JournalController {
  /// Rolls back the entire edit on failure, including recurring-series changes.
  /// Example: `try journal.commitChanges()` after staging a block insertion.
  func commitChanges() throws {
    do {
      try repository.save()
    } catch {
      repository.rollback()
      throw error
    }
  }

  func reportFailure(_ error: Error) {
    saveError = error.localizedDescription
    feedback?.report(.failure)
  }
}

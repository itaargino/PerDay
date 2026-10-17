import Foundation

/// Mutations share one transaction so a failed save cannot leave a partial edit.
@MainActor
protocol JournalRepository {
  func insert(_ block: NoteBlockModel)
  func delete(_ block: NoteBlockModel)
  func save() throws
  func rollback()
}

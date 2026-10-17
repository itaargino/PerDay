import SwiftData

@MainActor
struct SwiftDataJournalRepository: JournalRepository {
  let context: ModelContext

  func insert(_ block: NoteBlockModel) { context.insert(block) }
  func delete(_ block: NoteBlockModel) { context.delete(block) }
  func save() throws { try context.save() }
  func rollback() { context.rollback() }
}

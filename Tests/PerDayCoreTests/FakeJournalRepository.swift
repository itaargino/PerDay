import Foundation

@testable import PerDayCore

@MainActor
final class FakeJournalRepository: JournalRepository {
  var blocks: [NoteBlockModel]
  var rejectsSave: Bool = false
  private(set) var saveCount: Int = 0
  private(set) var rollbackCount: Int = 0
  private var inserted: [NoteBlockModel] = []
  private var deleted: Set<UUID> = []

  init(blocks: [NoteBlockModel] = []) { self.blocks = blocks }

  func insert(_ block: NoteBlockModel) { inserted.append(block) }
  func delete(_ block: NoteBlockModel) { deleted.insert(block.id) }

  func save() throws {
    saveCount += 1
    if rejectsSave {
      throw JournalEditError(message: "Fake store rejected save; expected writable storage.")
    }
    blocks.removeAll { deleted.contains($0.id) }
    blocks.append(contentsOf: inserted)
    inserted = []
    deleted = []
  }

  func rollback() {
    rollbackCount += 1
    inserted = []
    deleted = []
  }
}

@MainActor
final class FakeJournalFeedback: JournalFeedback {
  private(set) var events: [JournalFeedbackEvent] = []
  func report(_ event: JournalFeedbackEvent) { events.append(event) }
}

import Foundation
import Observation

@MainActor @Observable
final class JournalController {
  let repository: JournalRepository
  let feedback: JournalFeedback?
  let calendar: Calendar
  var blocks: [NoteBlockModel]
  var drafts: [BlockDraft] = []
  var saveError: String?
  var selectedDate: Date
  var isDeleting: Bool = false
  var lastRemoved: RemovedEntry?
  var removalDay: Date
  var undoPresentationID: UUID?

  enum RemovedEntry {
    case draft(BlockDraft)
    case block(BlockSnapshot)
  }

  init(
    repository: JournalRepository, blocks: [NoteBlockModel] = [],
    calendar: Calendar = .current, today: Date = .now, feedback: JournalFeedback? = nil
  ) {
    self.repository = repository
    self.feedback = feedback
    self.blocks = blocks
    self.calendar = calendar
    self.selectedDate = calendar.startOfDay(for: today)
    self.removalDay = today
  }

  var timeline: [JournalEntry] { entries(on: selectedDate) }

  func entries(on day: Date) -> [JournalEntry] {
    // SwiftData can publish an insertion before its editor is removed.
    // Keep one row per identity throughout the draft-to-saved handoff.
    let draftIDs = Set(drafts.map(\.id))
    let pending = drafts.filter { calendar.isDate($0.journalDate, inSameDayAs: day) }
    let saved = blocks.filter {
      !draftIDs.contains($0.id) && $0.occurs(on: day, calendar: calendar)
    }
    return (pending.map(JournalEntry.draft) + saved.map(JournalEntry.block))
      .sorted { $0.createdAt > $1.createdAt }
  }
}

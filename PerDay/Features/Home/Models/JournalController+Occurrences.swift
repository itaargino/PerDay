import Foundation

extension JournalController {
  /// Split the series at the selected day; the original keeps its past content
  /// and completion history. Single edits become detached, dated occurrences.
  /// Example: `try journal.saveOccurrence(draft, in: block, on: day, scope: .thisOccurrence)`.
  func saveOccurrence(
    _ draft: BlockDraft, in block: NoteBlockModel, on day: Date,
    scope: OccurrenceEditScope
  ) throws -> Date {
    let anchor = occurrenceAnchor(in: block, on: day)
    let edit = OccurrenceRevision(draft: draft, anchor: anchor, scope: scope, calendar: calendar)
    try edit.validate()
    let related = blocks.filter { ($0.seriesID ?? $0.id) == (block.seriesID ?? block.id) }
    let continuation = try edit.continuation(of: block, related: related)
    if scope == .thisOccurrence {
      block.excludedDays.append(anchor)
    } else {
      replaceFutureSegments(related, original: block, anchor: anchor)
    }
    block.updatedAt = .now
    repository.insert(continuation)
    return continuation.nextOccurrence(calendar: calendar) ?? edit.newStart
  }

  private func occurrenceAnchor(in block: NoteBlockModel, on day: Date) -> Date {
    let occurrence =
      block.isCreationRecord(on: day, calendar: calendar)
      ? (block.nextOccurrence(calendar: calendar) ?? block.componentStart(calendar: calendar)) : day
    return calendar.startOfDay(for: occurrence)
  }

  private func replaceFutureSegments(
    _ related: [NoteBlockModel], original: NoteBlockModel, anchor: Date
  ) {
    // Replace later segments and detached exceptions as part of the same
    // transaction, so editing an earlier segment cannot create duplicates.
    for segment in related {
      replaceSegment(segment, originalID: original.id, anchor: anchor)
    }
  }

  private func replaceSegment(_ segment: NoteBlockModel, originalID: UUID, anchor: Date) {
    let start = calendar.startOfDay(for: segment.componentStart(calendar: calendar))
    if segment.id != originalID && start >= anchor {
      repository.delete(segment)
      return
    }
    guard (segment.repeatUntil ?? .distantFuture) >= anchor else { return }
    segment.repeatUntil = calendar.date(byAdding: .day, value: -1, to: anchor)
    segment.updatedAt = .now
  }
}

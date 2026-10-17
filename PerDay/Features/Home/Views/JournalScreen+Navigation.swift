import SwiftUI

extension JournalScreen {
  func daySwipe(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { updateDayDrag($0, width: width) }
      .onEnded { finishDayDrag($0, width: width) }
  }

  private func updateDayDrag(_ value: DragGesture.Value, width: CGFloat) {
    guard !AppPlatform.isMac, !isEditingBlock, journal.drafts.isEmpty,
      !isSettlingDay, width > 0
    else { return }
    if dayDragAxis == nil {
      dayDragAxis =
        abs(value.translation.width) > abs(value.translation.height) * 1.5
        ? .horizontal : .vertical
    }
    guard dayDragAxis == .horizontal else { return }
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      previewDirection = value.translation.width < 0 ? 1 : -1
      dayOffset = min(width, max(-width, value.translation.width))
    }
  }

  private func finishDayDrag(_ value: DragGesture.Value, width: CGFloat) {
    guard !isSettlingDay else { return }
    let horizontal = dayDragAxis == .horizontal
    dayDragAxis = nil
    guard horizontal, width > 0 else { return }
    let decision = DaySwipeDecision(
      travel: value.translation.width,
      predictedTravel: value.predictedEndTranslation.width, width: width)
    let destination = journal.calendar.date(
      byAdding: .day, value: decision.direction, to: journal.selectedDate)
    settleDayDrag(decision, destination: destination)
  }

  private func settleDayDrag(_ decision: DaySwipeDecision, destination: Date?) {
    let changesDay = decision.shouldAdvance && destination != nil
    isSettlingDay = true
    AppPlatform.endEditing()
    let animation: Animation =
      reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 1)
    withAnimation(animation, completionCriteria: .removed) {
      dayOffset = changesDay ? decision.destinationOffset : 0
    } completion: {
      rebaseDay(destination: changesDay ? destination : nil)
    }
  }

  private func rebaseDay(destination: Date?) {
    // Rebase only after the neighboring page fills the viewport.
    // Persistent drag state avoids GestureState resetting before onEnded.
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      if let destination { journal.selectedDate = journal.calendar.startOfDay(for: destination) }
      dayOffset = 0
      previewDirection = nil
      isSettlingDay = false
    }
  }
}

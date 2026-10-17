@MainActor
protocol JournalFeedback {
  func report(_ event: JournalFeedbackEvent)
}

enum JournalFeedbackEvent { case success, failure, selection, tap }

struct JournalHapticFeedback: JournalFeedback {
  func report(_ event: JournalFeedbackEvent) {
    switch event {
    case .success: AppHaptics.success()
    case .failure: AppHaptics.error()
    case .selection: AppHaptics.selection()
    case .tap: AppHaptics.tap()
    }
  }
}

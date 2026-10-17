import Foundation

@MainActor
struct VoiceBlockInterpreter {
  let generator: VoiceBlockGenerating
  let calendar: Calendar
  let currentDate: () -> Date

  init(
    generator: VoiceBlockGenerating? = nil,
    calendar: Calendar = .current, currentDate: @escaping () -> Date = { .now }
  ) {
    self.generator = generator ?? AppleVoiceBlockGenerator()
    self.calendar = calendar
    self.currentDate = currentDate
  }

  /// Creates only components supported by the captured words.
  /// Example: `try await interpreter.interpret("Buy milk", journalDay: today)`.
  func interpret(_ transcript: String, journalDay: Date) async throws -> BlockDraft {
    let transcript = try CaptureTextValidator.validated(transcript)
    if let message = generator.unavailableMessage { throw VoiceBlockError(message: message) }
    let now = currentDate()
    let result = try await generator.generate(
      transcript: transcript, journalDay: journalDay, now: now)
    try Task.checkCancellation()
    return try VoiceDraftComposer(calendar: calendar, now: now)
      .compose(result, transcript: transcript, journalDay: journalDay)
  }
}

import Foundation
import FoundationModels

/// Apple Intelligence is isolated here so interpretation tests never invoke a model.
@MainActor
struct AppleVoiceBlockGenerator: VoiceBlockGenerating {
  var unavailableMessage: String? {
    switch SystemLanguageModel.default.availability {
    case .available: return nil
    case .unavailable(.deviceNotEligible):
      return
        "This device does not support Apple Intelligence. You can still create blocks manually."
    case .unavailable(.appleIntelligenceNotEnabled):
      return "Enable Apple Intelligence in Settings to create blocks with voice."
    case .unavailable(.modelNotReady):
      return "Apple Intelligence is still preparing its on-device model. Try again later."
    case .unavailable:
      return "The on-device model is currently unavailable. Try again later."
    }
  }

  func generate(transcript: String, journalDay: Date, now: Date) async throws -> VoiceBlockResult {
    let session = LanguageModelSession(instructions: VoiceCapturePrompt.instructions)
    do {
      let response = try await session.respond(
        to: capturePrompt(transcript: transcript, journalDay: journalDay, now: now),
        generating: VoiceBlockResult.self)
      return response.content
    } catch {
      try Task.checkCancellation()
      // A model that reports available can still fail inside Apple's runtime.
      // Keep the transcript and offer manual creation instead of a raw system error.
      throw VoiceBlockError(
        message:
          "Apple Intelligence couldn't interpret your words right now. Try again later, or create a block manually from the block picker."
      )
    }
  }

  private func capturePrompt(transcript: String, journalDay: Date, now: Date) -> String {
    let formatter = VoiceCaptureDateParser(calendar: .current).formatter(
      format: "yyyy-MM-dd'T'HH:mm")
    return """
      Current local date and time: \(formatter.string(from: now))
      Time zone: \(TimeZone.current.identifier)
      Selected journal day: \(formatter.string(from: journalDay))
      Transcript:
      \(transcript)
      """
  }
}

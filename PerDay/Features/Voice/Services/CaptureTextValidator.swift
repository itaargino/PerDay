import Foundation

enum CaptureTextValidator {
  static let maximumLength: Int = 6000

  static func validated(_ transcript: String) throws -> String {
    let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= maximumLength else {
      throw VoiceBlockError(
        message:
          "Capture contains \(trimmed.count) characters; expected 1...\(maximumLength). Review your capture and try again."
      )
    }
    return trimmed
  }
}

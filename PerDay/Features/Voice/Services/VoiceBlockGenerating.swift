import Foundation

@MainActor
protocol VoiceBlockGenerating {
  var unavailableMessage: String? { get }
  func generate(transcript: String, journalDay: Date, now: Date) async throws -> VoiceBlockResult
}

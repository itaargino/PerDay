import Foundation

@testable import PerDayCore

@MainActor
final class FakeVoiceBlockGenerator: VoiceBlockGenerating {
  var unavailableMessage: String?
  var result: VoiceBlockResult = VoiceBlockResult(
    text: "", textSource: nil, tasks: [], startDate: nil, dateSource: nil,
    startTime: nil, timeSource: nil, recurrence: nil, recurrenceSource: nil)
  var failure: Error?
  private(set) var requestCount: Int = 0
  private(set) var receivedTranscript: String?

  func generate(transcript: String, journalDay: Date, now: Date) async throws -> VoiceBlockResult {
    requestCount += 1
    receivedTranscript = transcript
    if let failure { throw failure }
    return result
  }
}

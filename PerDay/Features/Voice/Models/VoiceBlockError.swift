import Foundation

nonisolated struct VoiceBlockError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}

import Foundation

struct JournalEditError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}

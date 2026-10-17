import Foundation

struct VoiceCaptureDateParser {
  let calendar: Calendar

  func formatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = format
    formatter.isLenient = false
    return formatter
  }

  func parse(_ raw: String, format: String, relativeTo day: Date) throws -> Date {
    let formatter = formatter(format: format)
    // Parse wall-clock time on its actual schedule day, not DateFormatter's
    // default reference date, which can have a different UTC offset.
    formatter.defaultDate = day
    guard let date = formatter.date(from: raw), formatter.string(from: date) == raw else {
      throw VoiceBlockError(
        message:
          "Invalid schedule value '\(raw)'; expected a valid local date/time in \(format) format.")
    }
    return date
  }
}

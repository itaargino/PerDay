import Foundation

// Calendar arithmetic preserves local dates across daylight-saving transitions.
struct CalendarModel {
  var calendar: Calendar = .current

  func days(in month: Date) -> [Date] {
    guard let interval = calendar.dateInterval(of: .month, for: month),
      let range = calendar.range(of: .day, in: .month, for: month)
    else { return [] }
    return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: interval.start) }
  }

  func leadingDays(in month: Date) -> Int {
    guard let first = days(in: month).first else { return 0 }
    return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
  }

  var weekdaySymbols: [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
  }

  static func detectedDate(in text: String, relativeTo reference: Date = .now) -> Date? {
    // NSDataDetector understands explicit dates and localized date expressions.
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return detector.matches(in: text, range: range).first?.date
  }
}

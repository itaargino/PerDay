import Foundation

struct VoiceCaptureEvidence {
  let calendar: Calendar
  let now: Date

  /// Recover the spoken weekday when the model quotes only "every week" or
  /// drops the weekday from its date evidence. Multiple weekdays are ambiguous.
  func explicitWeekday(in transcript: String) -> String? {
    let pattern =
      #"\b(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|segundas?(?:[ -]feiras?)?|ter[cç]as?(?:[ -]feiras?)?|quartas?(?:[ -]feiras?)?|quintas?(?:[ -]feiras?)?|sextas?(?:[ -]feiras?)?|s[aá]bados?|domingos?)\b"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
      return nil
    }
    let matches = regex.matches(
      in: transcript, range: NSRange(transcript.startIndex..., in: transcript))
    guard matches.count == 1, let match = matches.first,
      let range = Range(match.range, in: transcript)
    else { return nil }
    return String(transcript[range])
  }

  /// Bare weekdays use the next occurrence including the selected day. "Next"
  /// excludes today; "last" resolves backwards relative to the actual current day.
  /// Explicit dates alongside a weekday remain the model's date extraction.
  func capturedWeekdayDate(_ source: String?, journalDay: Date) -> Date? {
    guard let source else { return nil }
    let input = source.folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: Locale(identifier: "en_US_POSIX"))
    let matches = weekdays.filter { input.range(of: $0.1, options: .regularExpression) != nil }
    guard matches.count == 1, let match = matches.first else { return nil }
    guard isWeekdayOnly(input, pattern: match.1) else { return nil }
    let isPast =
      input.range(of: #"\b(?:last|passada|passado|ultima|ultimo)\b"#, options: .regularExpression)
      != nil
    let isNext =
      input.range(of: #"\b(?:next|proxima|proximo)\b"#, options: .regularExpression) != nil
    let base = calendar.startOfDay(for: isPast ? now : journalDay)
    let weekday = calendar.component(.weekday, from: base)
    var offset = isPast ? -((weekday - match.0 + 7) % 7) : (match.0 - weekday + 7) % 7
    if offset == 0 && (isPast || isNext) { offset = isPast ? -7 : 7 }
    return calendar.date(byAdding: .day, value: offset, to: base)
  }

  /// Reject invented evidence before creating any component. Normalizing spacing
  /// handles speech transcription without accepting a quote absent from the input.
  func hasSource(_ source: String?, in transcript: String) -> Bool {
    guard let source else { return false }
    func normalized(_ value: String) -> String {
      value.folding(
        options: [.caseInsensitive, .diacriticInsensitive],
        locale: Locale(identifier: "en_US_POSIX")
      )
      .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
    let quote = normalized(source)
    guard !quote.isEmpty else { return false }
    let pattern =
      #"(?<![\p{L}\p{N}])"# + NSRegularExpression.escapedPattern(for: quote)
      + #"(?![\p{L}\p{N}])"#
    return normalized(transcript).range(of: pattern, options: .regularExpression) != nil
  }

  /// The model's classification alone cannot introduce repetition. Require a
  /// matching phrase in the original capture, for both typed and spoken input.
  func hasExplicitRecurrence(_ rule: VoiceRepeatRule, in transcript: String) -> Bool {
    let input = transcript.folding(
      options: [.caseInsensitive, .diacriticInsensitive],
      locale: Locale(identifier: "en_US_POSIX"))
    let pattern: String
    switch rule {
    case .daily:
      pattern = #"\b(?:(?:every|each)\s+day|(?:todo|cada)\s+dia|todos\s+os\s+dias)\b"#
    case .weekly:
      pattern =
        #"\b(?:(?:every|each|toda|todo|cada|todas\s+as|todos\s+os)\s+(?:week|weeks|semana|semanas|monday|tuesday|wednesday|thursday|friday|saturday|sunday|segundas?(?:[ -]feiras?)?|tercas?(?:[ -]feiras?)?|quartas?(?:[ -]feiras?)?|quintas?(?:[ -]feiras?)?|sextas?(?:[ -]feiras?)?|sabados?|domingos?))\b"#
    }
    return input.range(of: pattern, options: .regularExpression) != nil
  }
  private var weekdays: [(Int, String)] {
    [
      (1, #"\b(?:sunday|domingos?)\b"#),
      (2, #"\b(?:monday|segundas?(?:[ -]feiras?)?)\b"#),
      (3, #"\b(?:tuesday|tercas?(?:[ -]feiras?)?)\b"#),
      (4, #"\b(?:wednesday|quartas?(?:[ -]feiras?)?)\b"#),
      (5, #"\b(?:thursday|quintas?(?:[ -]feiras?)?)\b"#),
      (6, #"\b(?:friday|sextas?(?:[ -]feiras?)?)\b"#),
      (7, #"\b(?:saturday|sabados?)\b"#),
    ]
  }

  private func isWeekdayOnly(_ input: String, pattern: String) -> Bool {
    let remainder = input.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
      .replacingOccurrences(
        of:
          #"\b(?:on|this|next|last|every|each|the|na|no|nesta|neste|essa|esse|esta|este|toda|todo|todas|todos|as|os|cada|proxima|proximo|passada|passado|ultima|ultimo|feira)\b"#,
        with: "", options: .regularExpression)
    // Numbers, months, or other date qualifiers mean this is more than a
    // weekday-only expression; don't replace an explicitly stated date.
    return remainder.range(of: #"[\p{L}\p{N}]"#, options: .regularExpression) == nil
  }
}

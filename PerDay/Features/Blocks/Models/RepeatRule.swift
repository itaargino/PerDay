import Foundation

enum RepeatRule: String, Codable, CaseIterable, Identifiable {
  case never, daily, weekly
  var id: String { rawValue }
  var title: String {
    switch self {
    case .never: "Does not repeat"
    case .daily: "Every day"
    case .weekly: "Every week"
    }
  }
}

import Foundation

struct DaySwipeDecision {
  let travel: CGFloat
  let predictedTravel: CGFloat
  let width: CGFloat

  var direction: Int { travel < 0 ? 1 : -1 }
  var shouldAdvance: Bool {
    width > 0
      && (abs(travel) > width * 0.25 || (abs(travel) > 24 && abs(predictedTravel) > width * 0.45))
  }
  var destinationOffset: CGFloat { shouldAdvance ? (direction == 1 ? -width : width) : 0 }
}

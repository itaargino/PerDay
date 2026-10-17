import Foundation

/// Energy-based activity detection: wait for sustained sound, then 1.8s of
/// silence. Initial silence never submits an empty recording.
struct SpeechActivityDetector {
  private var voicedDuration: TimeInterval = 0
  private var lastSound: TimeInterval = 0
  private var noiseFloor: Float = -55
  private(set) var isSpeaking: Bool = false
  private(set) var hasEnded: Bool = false
  private(set) var level: CGFloat = 0.02

  mutating func sample(power: Float, elapsed: TimeInterval) {
    // Track quiet background levels, without calibrating on a spoken word.
    if power < -40 { noiseFloor = noiseFloor * 0.9 + power * 0.1 }
    isSpeaking = power > max(-42, noiseFloor + 12)
    level = CGFloat(min(1, max(0.02, (power + 55) / 45)))
    if isSpeaking {
      voicedDuration += 0.08
      lastSound = elapsed
    }
    hasEnded = (voicedDuration >= 0.32 && elapsed - lastSound >= 1.8) || elapsed >= 60
  }
}

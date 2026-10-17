import AVFoundation
import Foundation
import Observation
import Speech

/// Records a temporary local file, then transcribes it on device. Preparing
/// SpeechTranscriber assets avoids depending on the legacy recognizer service.
@MainActor @Observable
final class VoiceRecorder {
  var transcript: String = ""
  var isRecording: Bool = false
  var isStarting: Bool = false
  var isSpeaking: Bool = false
  var speechEnded: Bool = false
  var waveform: [CGFloat] = Array(repeating: 0.02, count: 36)
  var elapsed: TimeInterval = 0
  private var meterTask: Task<Void, Never>?
  var preparationMessage: String = "Preparing microphone…"
  var errorMessage: String?
  var languageIdentifier = Locale.preferredLanguages.first ?? "en-US"
  private var audioRecorder: AVAudioRecorder?
  private var audioURL: URL?
  private var transcriber: SpeechTranscriber?
  private var analyzer: SpeechAnalyzer?
  private var resultTask: Task<Void, Error>?
  private var captureID: UUID?
  private let temporaryDirectory: URL
  private let fileSystem: FileManager

  init(fileSystem: FileManager = .default, temporaryDirectory: URL? = nil) {
    self.fileSystem = fileSystem
    self.temporaryDirectory = temporaryDirectory ?? fileSystem.temporaryDirectory
  }

  func start() async {
    guard !isStarting, !isRecording else { return }
    cancel()
    isStarting = true
    errorMessage = nil
    preparationMessage = "Preparing microphone…"
    let id = UUID()
    captureID = id
    defer { isStarting = false }
    do { try await prepareRecording(id: id) } catch { recoverPreparation(error, id: id) }
  }

  private func prepareRecording(id: UUID) async throws {
    try await requestMicrophone(id: id)
    transcriber = try await prepareTranscriber(id: id)
    try ensureActive(id)
    try startAudioFile(id: id)
    isRecording = true
    monitorSpeech(id: id)
    AppHaptics.tap()
  }

  private func requestMicrophone(id: UUID) async throws {
    let allowed = await withCheckedContinuation { continuation in
      AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
    }
    try ensureActive(id)
    guard allowed else {
      throw VoiceBlockError(
        message: AppPlatform.isMac
          ? "Microphone permission is denied; expected access in System Settings → Privacy & Security → Microphone."
          : "Microphone permission is denied; expected access for PerDay in Settings.")
    }
  }

  private func prepareTranscriber(id: UUID) async throws -> SpeechTranscriber {
    guard SpeechTranscriber.isAvailable,
      let locale = await SpeechTranscriber.supportedLocale(
        equivalentTo: Locale(identifier: languageIdentifier))
    else {
      throw VoiceBlockError(
        message:
          "Speech language '\(languageIdentifier)' is unavailable; expected a supported on-device speech language. Choose another language or type your words."
      )
    }
    try ensureActive(id)
    let module = SpeechTranscriber(locale: locale, preset: .transcription)
    preparationMessage = "Preparing speech language…"
    if let installation = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
      preparationMessage = "Downloading speech language…"
      try await installation.downloadAndInstall()
    }
    return module
  }

  private func startAudioFile(id: UUID) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true)
    let url = temporaryDirectory.appendingPathComponent("PerDay-voice-\(id).caf")
    audioURL = url
    let recorder = try makeAudioRecorder(url: url)
    audioRecorder = recorder
    guard recorder.record() else {
      throw VoiceBlockError(
        message:
          "Microphone returned record=false; expected an active recording. Check that it isn't in use and try again."
      )
    }
  }

  private func makeAudioRecorder(url: URL) throws -> AVAudioRecorder {
    let recorder = try AVAudioRecorder(
      url: url,
      settings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
      ])
    recorder.isMeteringEnabled = true
    return recorder
  }

  private func recoverPreparation(_ error: Error, id: UUID) {
    let cancelled = Task.isCancelled || captureID != id
    cancel()
    guard !cancelled else { return }
    errorMessage =
      (error as? VoiceBlockError)?.message
      ?? "Couldn't prepare on-device speech. Check your connection for the language download, then try again. You can also type your words."
  }

  func finish() async throws {
    guard let id = captureID, let url = audioURL, let module = transcriber else {
      throw VoiceBlockError(
        message:
          "Recording state is empty; expected an active capture with an audio file and transcriber. Try recording again."
      )
    }
    stopAudio()
    let analyzer = SpeechAnalyzer(modules: [module])
    self.analyzer = analyzer
    resultTask = consumeTranscription(module, id: id)
    defer { cancel() }
    try await finishTranscription(analyzer, url: url, id: id)
  }

  private func finishTranscription(_ analyzer: SpeechAnalyzer, url: URL, id: UUID) async throws {
    do {
      try await analyzeAudio(analyzer, url: url)
      try await resultTask?.value
      try ensureActive(id)
    } catch {
      if Task.isCancelled || captureID != id { throw CancellationError() }
      throw VoiceBlockError(
        message:
          "Couldn't transcribe this recording. Your existing words are preserved. Try another speech language or type your words below."
      )
    }
  }

  private func consumeTranscription(_ module: SpeechTranscriber, id: UUID) -> Task<Void, Error> {
    let prefix = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    // Consume every final segment before allowing block interpretation.
    return Task { @MainActor [weak self] in
      var segments: [String] = []
      for try await result in module.results {
        try Task.checkCancellation()
        guard let self, self.captureID == id else { throw CancellationError() }
        segments.append(String(result.text.characters))
        self.transcript = ([prefix] + segments).filter { !$0.isEmpty }.joined(separator: " ")
      }
    }
  }

  private func analyzeAudio(_ analyzer: SpeechAnalyzer, url: URL) async throws {
    let file = try AVAudioFile(forReading: url)
    guard let lastTime = try await analyzer.analyzeSequence(from: file) else {
      await analyzer.cancelAndFinishNow()
      throw VoiceBlockError(
        message:
          "Captured audio has no samples; expected a nonempty recording. Try recording again.")
    }
    try await analyzer.finalizeAndFinish(through: lastTime)
  }

  func cancel() {
    captureID = nil
    stopAudio()
    resultTask?.cancel()
    resultTask = nil
    if let analyzer { Task { await analyzer.cancelAndFinishNow() } }
    analyzer = nil
    transcriber = nil
    if let audioURL { try? fileSystem.removeItem(at: audioURL) }
    audioURL = nil
  }

  private func ensureActive(_ id: UUID) throws {
    try Task.checkCancellation()
    guard captureID == id else { throw CancellationError() }
  }

  private func monitorSpeech(id: UUID) {
    speechEnded = false
    elapsed = 0
    waveform = Array(repeating: 0.02, count: 36)
    meterTask = Task { @MainActor [weak self] in
      var detector = SpeechActivityDetector()
      while !Task.isCancelled {
        do { try await Task.sleep(for: .milliseconds(80)) } catch { return }
        guard let self, self.captureID == id else { return }
        guard self.sampleMicrophone(using: &detector) else { return }
      }
    }
  }

  private func sampleMicrophone(using detector: inout SpeechActivityDetector) -> Bool {
    guard let recorder = audioRecorder else { return false }
    guard recorder.isRecording else {
      errorMessage = "Recording stopped unexpectedly. Please try again."
      stopAudio()
      return false
    }
    recorder.updateMeters()
    elapsed = recorder.currentTime
    detector.sample(power: recorder.averagePower(forChannel: 0), elapsed: elapsed)
    isSpeaking = detector.isSpeaking
    waveform.removeFirst()
    waveform.append(detector.level)
    speechEnded = detector.hasEnded
    return !speechEnded
  }

  private func stopAudio() {
    meterTask?.cancel()
    meterTask = nil
    isSpeaking = false
    audioRecorder?.stop()
    audioRecorder = nil
    isRecording = false
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}

import AVFoundation
import Combine
import SwiftUI

/// Compact voice-only capture. Typed words and recovery live in the block picker.
struct VoiceBlockView: View {
  var interpreter: VoiceBlockInterpreter = VoiceBlockInterpreter()
  let journalDay: Date
  let onCreate: (BlockDraft) throws -> Void
  let onReview: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var recorder = VoiceRecorder()
  @State private var operation: Task<Void, Never>?
  @State private var isCreating: Bool = false
  @State private var didCreate: Bool = false
  @State private var errorMessage: String?

  private var message: String? { errorMessage ?? recorder.errorMessage }
  private var status: String {
    if isCreating { return "Creating…" }
    if recorder.isStarting { return recorder.preparationMessage }
    if message != nil { return "Capture paused" }
    return recorder.isSpeaking ? "Speaking…" : "Listening…"
  }

  var body: some View {
    ScrollView { captureContent }
      .scrollBounceBehavior(.basedOnSize)
      .task { startListening() }
      .onChange(of: recorder.speechEnded) { _, ended in
        if ended && recorder.isRecording { createBlock() }
      }
      .onDisappear { stopOperations() }
      .onReceive(
        NotificationCenter.default.publisher(for: AVAudioSession.didBecomeInactiveNotification)
      ) {
        receiveAudioInterruption($0)
      }
      .onChange(of: scenePhase) { _, phase in if phase == .background { stopOperations() } }
  }

  private var captureContent: some View {
    VStack(spacing: 24) {
      captureHeading
      recordingMeter
      captureControls
    }
    .frame(maxWidth: 480).frame(maxWidth: .infinity)
    .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 24)
  }

  private var captureHeading: some View {
    VStack(spacing: 8) {
      Label("Intelligent Capture", systemImage: "sparkles").font(.headline)
      Text("Speak naturally. Turn your thoughts into a block.")
        .font(.subheadline).foregroundStyle(.secondary)
        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }
  }

  private var recordingMeter: some View {
    VStack(spacing: 16) {
      recordingStatus
      recordingWaveform
    }
    .padding(20)
    .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 24))
  }

  private var recordingStatus: some View {
    HStack(spacing: 8) {
      Image(systemName: message != nil ? "exclamationmark.circle" : "mic.fill")
        .foregroundStyle(message != nil ? Color.secondary : Color.accentColor)
      Text(status).font(.subheadline.weight(.medium))
      Spacer(minLength: 12)
      Text(elapsedTime).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
        .accessibilityLabel("Recording time, \(Int(recorder.elapsed)) seconds")
    }
  }

  private var recordingWaveform: some View {
    HStack(spacing: 3) {
      ForEach(recorder.waveform.indices, id: \.self) { index in
        Capsule().fill(Color.accentColor.opacity(recorder.isSpeaking ? 1 : 0.45))
          .frame(maxWidth: .infinity).frame(height: 3 + recorder.waveform[index] * 56)
      }
    }
    .frame(height: 64)
    .animation(reduceMotion ? nil : .linear(duration: 0.08), value: recorder.waveform)
    .accessibilityHidden(true)
  }

  private func receiveAudioInterruption(_ notification: Notification) {
    guard
      let context = notification.userInfo?[AVAudioSession.deactivationContextKey]
        as? AVAudioSession.DeactivationContext,
      context.source == .system, recorder.isRecording || recorder.isStarting
    else { return }
    stopOperations()
    errorMessage = "Recording was interrupted. Try again."
  }

  private var elapsedTime: String {
    let seconds = Int(recorder.elapsed)
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }

  @ViewBuilder
  private var captureControls: some View {
    if let message {
      recoveryPanel(message)
    } else if isCreating || recorder.isStarting {
      ProgressView().frame(height: 48).accessibilityLabel(status)
    } else {
      finishControls
    }
  }

  private func recoveryPanel(_ message: String) -> some View {
    VStack(spacing: 16) {
      Text(message).font(.footnote).foregroundStyle(.secondary)
        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 12) { recoveryActions }
        VStack(spacing: 12) { recoveryActions }
      }
    }
  }

  private var finishControls: some View {
    VStack(spacing: 10) {
      Button(action: createBlock) {
        Label("Finish capture", systemImage: "stop.fill").font(.body.weight(.semibold))
          .frame(maxWidth: .infinity, minHeight: 44)
      }
      .buttonStyle(.glassProminent).buttonBorderShape(.capsule)
      .disabled(!recorder.isRecording || didCreate).accessibilityLabel("Stop and create block")
      Text("Capture finishes automatically when you pause.")
        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  private var recoveryActions: some View {
    Button("Retry") {
      if recorder.transcript.isEmpty { startListening() } else { createBlock() }
    }
    .buttonStyle(.glass)
    .controlSize(.large)
    Button("Review capture") {
      onReview(recorder.transcript)
      dismiss()
    }
    .buttonStyle(.glassProminent)
    .controlSize(.large)
  }

  private func startListening() {
    guard !isCreating, !didCreate else { return }
    errorMessage = nil
    operation = Task { await recorder.start() }
  }

  private func createBlock() {
    guard !isCreating, !didCreate, !recorder.isStarting else { return }
    isCreating = true
    errorMessage = nil
    let wasRecording = recorder.isRecording
    operation = Task { await finishCapture(wasRecording: wasRecording) }
  }

  private func finishCapture(wasRecording: Bool) async {
    defer { isCreating = false }
    do {
      if wasRecording { try await recorder.finish() }
      let draft = try await interpreter.interpret(recorder.transcript, journalDay: journalDay)
      try Task.checkCancellation()
      try onCreate(draft)
      didCreate = true
      AppHaptics.success()
      dismiss()
    } catch is CancellationError {
    } catch {
      guard !Task.isCancelled else { return }
      errorMessage = error.localizedDescription
      AppHaptics.error()
    }
  }

  private func stopOperations() {
    operation?.cancel()
    recorder.cancel()
  }
}

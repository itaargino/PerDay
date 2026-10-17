import SwiftUI

struct BlockPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var hasSelectedBlock: Bool = false
  @State private var isInterpreting: Bool = false
  @State private var captureError: String?
  @State private var captureOperation: Task<Void, Never>?
  var interpreter: VoiceBlockInterpreter = VoiceBlockInterpreter()
  let canDelete: Bool
  let journalDay: Date
  @Binding var captureText: String
  let onCreateCapture: (BlockDraft) throws -> Void
  let onSelect: (BlockKind) -> Void
  let onDelete: () -> Void

  var body: some View {
    NavigationStack {
      List {
        intelligentCaptureSection
        blockChoicesSection
      }
      .listStyle(.insetGrouped)
      .onDisappear { captureOperation?.cancel() }
      .modifier(KeyboardDismissToolbar())
      .navigationTitle("Blocks").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            AppHaptics.tap()
            dismiss()
          }
        }
      }
    }
  }

  private var intelligentCaptureSection: some View {
    Section("Intelligent Capture") {
      TextField("Write what’s on your mind…", text: $captureText, axis: .vertical)
        .lineLimit(1...4)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
        .disabled(isInterpreting).accessibilityLabel("Intelligent Capture")
        .listRowSeparator(.hidden)
      if let captureError {
        Text(captureError).font(.footnote).foregroundStyle(.secondary).listRowSeparator(.hidden)
      }
      captureSubmitRow
    }
  }

  private var captureSubmitRow: some View {
    HStack {
      Spacer()
      if isInterpreting { ProgressView() } else { captureSubmitButton }
    }
    .disabled(
      isInterpreting || hasSelectedBlock
        || captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    )
    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    .listRowSeparator(.hidden)
  }

  private var captureSubmitButton: some View {
    Button(action: createCapture) {
      Image(systemName: "sparkles").font(.body.weight(.semibold))
        .frame(width: 44, height: 44).contentShape(Circle())
    }
    .buttonStyle(.plain).foregroundStyle(.white)
    .glassEffect(.regular.tint(.accentColor).interactive(), in: Circle())
    .accessibilityLabel("Create from Intelligent Capture")
  }

  private var blockChoicesSection: some View {
    Section {
      ForEach(BlockKind.allCases) { kind in
        Button {
          selectBlockKind(kind)
        } label: {
          blockChoiceLabel(kind)
        }
        .buttonStyle(JournalRowButtonStyle()).disabled(hasSelectedBlock || isInterpreting)
        .accessibilityHint("Adds a new block to the journal")
      }
    } header: {
      Text("Start a block")
    } footer: {
      Text("Choose a block to write in your timeline.")
    }
  }

  private func blockChoiceLabel(_ kind: BlockKind) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: kind.symbol).font(.title3).foregroundStyle(Color.accentColor)
        .frame(width: 28).padding(.top, 2)
      VStack(alignment: .leading, spacing: 4) {
        Text(kind.title).font(.headline).foregroundStyle(.primary)
        Text(description(for: kind)).font(.subheadline).foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, minHeight: JournalStyle.touchTarget, alignment: .leading)
    .contentShape(Rectangle())
  }

  private func selectBlockKind(_ kind: BlockKind) {
    guard !hasSelectedBlock else { return }
    hasSelectedBlock = true
    AppHaptics.selection()
    onSelect(kind)
  }

  private func createCapture() {
    guard !isInterpreting, !hasSelectedBlock else { return }
    guard !captureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    isInterpreting = true
    captureError = nil
    captureOperation = Task { await interpretCapture() }
  }

  private func interpretCapture() async {
    defer { isInterpreting = false }
    do {
      let draft = try await interpreter.interpret(captureText, journalDay: journalDay)
      try Task.checkCancellation()
      try onCreateCapture(draft)
      hasSelectedBlock = true
      captureText = ""
      AppHaptics.success()
      dismiss()
    } catch {
      guard !Task.isCancelled else { return }
      captureError = error.localizedDescription
      AppHaptics.error()
    }
  }

  private func description(for kind: BlockKind) -> String {
    switch kind {
    case .basic: "Start an empty block and add components."
    case .text: "Capture a thought or just mind dump."
    case .task: "Write something you want to get done."
    case .agenda: "Put a plan or event on your calendar."
    }
  }
}

import SwiftUI

extension JournalScreen {
  @ViewBuilder
  var voiceButton: some View {
    if !AppPlatform.isMac && !journal.isDeleting && !isEditingBlock && journal.drafts.isEmpty {
      Button {
        AppHaptics.tap()
        showingVoice = true
      } label: {
        Image(systemName: "mic.fill").font(.title3).frame(width: 56, height: 56)
      }
      .buttonStyle(.glass)
      .buttonBorderShape(.circle)
      .accessibilityLabel("Voice capture")
      .accessibilityHint("Create a block using your voice")
      .padding(16)
    }
  }

  var undoPresentation: some View {
    VStack(spacing: 12) { if journal.lastRemoved != nil { undoBanner } }
      .frame(maxWidth: 480)
      .padding(.horizontal, 16)
      .padding(.bottom, 12)
  }

  var desktopControls: some View {
    HStack(spacing: 12) {
      desktopCaptureButtons
      Spacer()
      if journal.lastRemoved != nil {
        Button("Undo Delete", action: journal.undoDeletion)
          .keyboardShortcut("z", modifiers: [.command, .shift])
          .help("Restore the last deleted block (⇧⌘Z)")
      }
    }
    .buttonStyle(.bordered)
    .padding(.horizontal, JournalStyle.margin)
    .padding(.bottom, 12)
    .frame(maxWidth: 860)
  }

  private var desktopCaptureButtons: some View {
    Group {
      Button {
        showingBlockPicker = true
      } label: {
        Label("New Block", systemImage: "plus")
      }
      .keyboardShortcut("n", modifiers: .command)
      .disabled(isEditingBlock || !journal.drafts.isEmpty || journal.isDeleting)
      .help("Create a block (⌘N)")

      Button {
        showingVoice = true
      } label: {
        Label("Voice Capture", systemImage: "mic")
      }
      .keyboardShortcut("r", modifiers: [.command, .shift])
      .disabled(isEditingBlock || !journal.drafts.isEmpty || journal.isDeleting)
      .help("Record a voice capture (⇧⌘R)")
    }
  }

  var undoBanner: some View {
    HStack(spacing: 12) {
      Label("Block deleted", systemImage: "trash")
        .font(.subheadline)
      Spacer(minLength: 0)
      Button("Undo", action: journal.undoDeletion)
        .font(.body.weight(.semibold))
        .frame(minHeight: 44)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
  }

  func draftBinding(for draft: BlockDraft) -> Binding<BlockDraft> {
    Binding(
      get: { journal.drafts.first { $0.id == draft.id } ?? draft },
      set: { updated in
        if let index = journal.drafts.firstIndex(where: { $0.id == draft.id }) {
          journal.drafts[index] = updated
        }
      }
    )
  }

  func beginDeletion() {
    AppPlatform.endEditing()
    journal.beginDeletion()
    AppHaptics.warning()
  }
}

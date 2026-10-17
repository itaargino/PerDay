import SwiftUI

struct BlockEditorView: View {
  @Binding var draft: BlockDraft
  let onSave: () -> Void
  let onCancel: () -> Void
  @State private var confirmingDiscard: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      ComponentListEditor(components: $draft.components, defaultDate: draft.agendaDate)
      Divider()
      editorActions
    }
    .journalCard()
    .preference(key: BlockEditingKey.self, value: true)
    .confirmationDialog(
      "Discard this block?", isPresented: $confirmingDiscard, titleVisibility: .visible
    ) {
      Button("Discard Block", role: .destructive) {
        AppHaptics.tap()
        onCancel()
      }
      Button("Keep Editing", role: .cancel) {}
    }
  }
  private var editorActions: some View {
    HStack {
      Button("Cancel") { confirmingDiscard = true }.buttonStyle(.bordered)
      Spacer()
      Button("Save", action: onSave)
        .buttonStyle(.borderedProminent)
        .disabled(!draft.canSave)
        .keyboardShortcut("s", modifiers: .command)
    }
  }

}

/// Home hides floating capture controls while any inline block editor is open.
struct BlockEditingKey: PreferenceKey {
  static var defaultValue: Bool { false }
  static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

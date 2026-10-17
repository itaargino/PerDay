import SwiftUI

/// Recovery remains independent of both speech and Foundation Models.
struct VoiceManualBlockView: View {
  @State var draft: BlockDraft
  let onCreate: (BlockDraft) throws -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var isSaving: Bool = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        BlockEditorView(draft: $draft, onSave: save, onCancel: { dismiss() })
          .disabled(isSaving)
          .padding(16)
      }
      .background(Color(uiColor: .systemGroupedBackground))
      .modifier(KeyboardDismissToolbar())
      .navigationTitle("Create \(draft.kind.title)")
      .navigationBarTitleDisplayMode(.inline)
      .alert(
        "Couldn't Save Block",
        isPresented: saveErrorPresented
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(errorMessage ?? "Try again.")
      }
    }
  }

  private var saveErrorPresented: Binding<Bool> {
    Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
  }

  private func save() {
    guard !isSaving, draft.canSave else { return }
    isSaving = true
    do {
      try onCreate(draft)
      AppHaptics.success()
      dismiss()
    } catch {
      isSaving = false
      errorMessage = error.localizedDescription
      AppHaptics.error()
    }
  }
}

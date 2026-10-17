import SwiftUI

struct DraftPreviewCard: View {
  let draft: BlockDraft

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("New \(draft.kind.title.lowercased()) block").font(.headline)
      Text(previewText)
    }
    .journalCard()
  }

  private var previewText: String {
    draft.components.flatMap { component in
      component.kind == .taskList ? component.tasks.map(\.text) : [component.text]
    }.filter { !$0.isEmpty }.joined(separator: "\n")
  }
}

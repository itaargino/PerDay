import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \NoteBlockModel.createdAt, order: .reverse)
  private var blocks: [NoteBlockModel]

  var body: some View {
    JournalScreen(blocks: blocks, repository: SwiftDataJournalRepository(context: modelContext))
  }
}

#Preview {
  HomeView().modelContainer(for: NoteBlockModel.self, inMemory: true)
}

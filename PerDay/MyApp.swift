import SwiftData
import SwiftUI

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      HomeView()
        .background(JournalWindowConfiguration().allowsHitTesting(false))
    }
    .modelContainer(for: NoteBlockModel.self)
  }
}

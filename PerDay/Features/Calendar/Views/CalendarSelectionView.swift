import SwiftUI

/// The system calendar supplies localized month navigation and date selection.
struct CalendarSelectionView: View {
  @Binding var selectedDate: Date
  let blocks: [NoteBlockModel]
  @Environment(\.dismiss) private var dismiss

  private var dayBlocks: [NoteBlockModel] {
    blocks.filter { $0.occurs(on: selectedDate) }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          DatePicker("Journal date", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.graphical)
        }
        daySummarySection
      }
      .listStyle(.insetGrouped).navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
      .toolbar { calendarToolbar }
    }
    .presentationDetents([.large]).presentationDragIndicator(.visible)
  }

  @ToolbarContentBuilder
  private var calendarToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button("Today") { selectedDate = Calendar.current.startOfDay(for: .now) }
    }
    ToolbarItem(placement: .confirmationAction) {
      Button("Done") {
        AppHaptics.tap()
        dismiss()
      }
    }
  }

  private var daySummarySection: some View {
    Section {
      if dayBlocks.isEmpty {
        Text("No blocks yet. Select this day and pull down in your journal to add one.")
          .font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
      } else {
        componentCounts
      }
    } header: {
      Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
    }
  }

  private var componentCounts: some View {
    Group {
      Label(
        "\(dayBlocks.count) \(dayBlocks.count == 1 ? "block" : "blocks")",
        systemImage: "square.stack")
      ForEach(ComponentKind.allCases) { kind in componentCountLabel(kind) }
    }
  }

  @ViewBuilder
  private func componentCountLabel(_ kind: ComponentKind) -> some View {
    let count = dayBlocks.flatMap(\.components).filter { $0.kind == kind }.count
    if count > 0 {
      Label(
        "\(count) \(kind.title.lowercased()) \(count == 1 ? "component" : "components")",
        systemImage: kind.symbol)
    }
  }
}

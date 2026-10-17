import SwiftUI

struct AgendaCardView: View {
  let block: NoteBlockModel
  let selectedDay: Date
  let onSave: (String, Date, RepeatRule, [Int]) -> Bool
  @State private var isEditing: Bool = false
  @State private var text: String = ""
  @State private var start = Date.now
  @State private var recurrence: RepeatRule = .never
  @State private var weekdays: [Int] = []
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var occurrence: Date? { block.agendaStart(on: selectedDay) }
  private var displayedStart: Date { occurrence ?? block.noteDate }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if isEditing { eventEditor } else { eventSummary }
    }
    .journalCard()
  }

  private var eventEditor: some View {
    Group {
      Text("Edit event").font(.headline)
      TextField("Event", text: $text, axis: .vertical).font(.body).lineLimit(1...)
      AgendaScheduleEditor(start: $start, recurrence: $recurrence, weekdays: $weekdays)
      if block.recurrence != .never {
        Text("Changes apply to the entire repeating event.").font(.footnote).foregroundStyle(
          .secondary)
      }
      eventEditorActions
    }
  }

  @ViewBuilder
  private var eventEditorActions: some View {
    if dynamicTypeSize.isAccessibilitySize {
      VStack(alignment: .leading, spacing: 8) {
        saveButton
        cancelButton
      }
    } else {
      HStack {
        cancelButton
        Spacer()
        saveButton
      }
    }
  }

  private var eventSummary: some View {
    HStack(alignment: .top, spacing: 8) {
      // The menu's touch target must not set the text row's height.
      VStack(alignment: .leading, spacing: 8) {
        Text(block.noteText).font(.body).fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, alignment: .leading)
        eventSchedule
        if block.recurrence != .never {
          Label(repeatDescription, systemImage: "repeat").font(.subheadline)
            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
      }
      eventActionsMenu
    }
  }

  private var eventSchedule: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(occurrence == nil ? "First event starts" : "Starts").font(.caption).foregroundStyle(
        .secondary)
      Text(displayedStart, format: .dateTime.hour().minute()).font(.title2.weight(.semibold))
        .monospacedDigit()
      Text(displayedStart, format: .dateTime.weekday(.wide).month(.wide).day().year())
        .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
  }

  private var eventActionsMenu: some View {
    Menu {
      Button("Edit event", systemImage: "pencil", action: beginEventEditing)
    } label: {
      Image(systemName: "ellipsis").frame(width: 44, height: 44).contentShape(Rectangle())
    }
    .accessibilityLabel("Event actions")
  }

  private func beginEventEditing() {
    AppHaptics.tap()
    text = block.noteText
    start = block.noteDate
    recurrence = block.recurrence
    weekdays = block.weekdays
    isEditing = true
  }

  private var repeatDescription: String {
    var component = JournalComponent(kind: .recurrence)
    component.recurrence = block.recurrence
    component.recurrenceWeekdays = block.weekdays
    return component.recurrenceSummary(start: block.noteDate)
  }

  private var cancelButton: some View {
    Button("Cancel") {
      AppHaptics.tap()
      isEditing = false
    }.buttonStyle(.bordered)
  }

  private var saveButton: some View {
    Button("Save") {
      if onSave(text, start, recurrence, weekdays) { isEditing = false }
    }
    .buttonStyle(.borderedProminent)
    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }
}

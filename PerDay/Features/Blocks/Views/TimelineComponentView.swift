import SwiftUI

struct TimelineComponentView: View {
  let component: JournalComponent
  let block: NoteBlockModel
  let completionDay: Date
  let isCreationRecord: Bool
  let isSkipped: Bool
  let onToggleItem: (UUID, UUID) -> Void

  var body: some View {
    switch component.kind {
    case .text: Text(component.text).font(.body).fixedSize(horizontal: false, vertical: true)
    case .startDate: dateLabel
    case .startTime: timeLabel
    case .recurrence:
      Label(component.recurrenceSummary(start: block.componentStart()), systemImage: "repeat")
        .font(.subheadline).foregroundStyle(.secondary)
    case .taskList: taskList
    }
  }

  private var dateLabel: some View {
    Label {
      Text(
        block.componentRecurrence != .never && !isCreationRecord ? completionDay : component.date,
        format: .dateTime.weekday(.wide).month(.wide).day().year())
    } icon: {
      Image(systemName: "calendar")
    }
    .font(.subheadline).foregroundStyle(.secondary)
  }

  private var timeLabel: some View {
    Label {
      Text(component.date, format: .dateTime.hour().minute()).monospacedDigit()
    } icon: {
      Image(systemName: "clock")
    }
    .font(.subheadline).foregroundStyle(.secondary)
  }

  private var taskList: some View {
    VStack(alignment: .leading, spacing: 4) {
      if !isCreationRecord && !isSkipped {
        Text("\(completedTaskCount) of \(component.tasks.count) completed")
          .font(.footnote).foregroundStyle(.secondary)
      }
      ForEach(component.tasks) { item in taskRow(item) }
    }
  }

  private var completedTaskCount: Int {
    component.tasks.filter { $0.isCompleted(on: completionDay) }.count
  }

  private func taskRow(_ item: TaskItem) -> some View {
    HStack(alignment: .top, spacing: 8) {
      taskMarker(item)
      Text(item.text)
        .strikethrough(!isCreationRecord && !isSkipped && item.isCompleted(on: completionDay))
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 10)
    }
  }

  @ViewBuilder
  private func taskMarker(_ item: TaskItem) -> some View {
    if isCreationRecord || isSkipped {
      Image(systemName: "circle.fill").font(.system(size: 5))
        .foregroundStyle(.secondary).frame(width: 20, height: 44).accessibilityHidden(true)
    } else {
      completionButton(item)
    }
  }

  private func completionButton(_ item: TaskItem) -> some View {
    Button {
      onToggleItem(component.id, item.id)
    } label: {
      Image(systemName: item.isCompleted(on: completionDay) ? "checkmark.circle.fill" : "circle")
        .font(.title3).frame(width: 44, height: 44)
    }
    .buttonStyle(JournalRowButtonStyle())
    .accessibilityLabel(item.text)
    .accessibilityValue(item.isCompleted(on: completionDay) ? "Completed" : "Incomplete")
  }
}

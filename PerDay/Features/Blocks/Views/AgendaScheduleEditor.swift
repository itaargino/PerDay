import SwiftUI

struct AgendaScheduleEditor: View {
  @Binding var start: Date
  @Binding var recurrence: RepeatRule
  @Binding var weekdays: [Int]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      DatePicker("Start date", selection: $start, displayedComponents: .date)
      DatePicker("Start time", selection: $start, displayedComponents: .hourAndMinute)
      RecurrenceEditor(
        component: Binding(
          get: {
            var component = JournalComponent(kind: .recurrence)
            component.recurrence = recurrence
            component.recurrenceWeekdays = weekdays
            return component
          },
          set: { component in
            recurrence = component.recurrence
            weekdays = component.recurrenceWeekdays ?? []
          }), start: start)
    }
    .font(.body)
  }
}

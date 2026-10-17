import SwiftUI

/// A native two-choice picker reveals independent weekday toggle buttons.
struct RecurrenceEditor: View {
  @Binding var component: JournalComponent
  let start: Date
  @Environment(\.calendar) private var calendar
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ScaledMetric(relativeTo: .body) private var markerDiameter: CGFloat = 48

  private let shortNames = ["S", "M", "T", "W", "T", "F", "S"]
  private let fullNames = [
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
  ]

  private var stripHeight: CGFloat { max(44, min(markerDiameter, 64)) }

  private var isRecurring: Binding<Bool> {
    Binding(
      get: { component.recurrence != .never },
      set: { enabled in
        var updated = component
        if enabled {
          if (updated.recurrenceWeekdays ?? []).isEmpty {
            updated.recurrenceWeekdays = [calendar.component(.weekday, from: start)]
          }
          updated.recurrence = .weekly
        } else {
          // Preserve the selection if recurrence is enabled again in this editor.
          updated.recurrenceWeekdays = component.selectedWeekdays(start: start, calendar: calendar)
          updated.recurrence = .never
        }
        component = updated
        AppHaptics.selection()
      })
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      recurrencePicker
      recurrenceDetails
    }
  }

  var recurrencePicker: some View {
    Picker("Recurrence", selection: isRecurring) {
      Text("Does not repeat").tag(false)
      Text("Recurring").tag(true)
    }
    .pickerStyle(.menu)
    .frame(minHeight: 44)
  }

  @ViewBuilder
  var recurrenceDetails: some View {
    if component.recurrence != .never {
      VStack(alignment: .leading, spacing: 12) {
        Text("Days of the week")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        weekdayStrip
        Text(component.recurrenceSummary(start: start, calendar: calendar))
          .font(.footnote)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  // Like Anama, keep the full week visible; larger type changes the marker
  // shape instead of breaking the week into multiple rows.
  private var weekdayStrip: some View {
    GeometryReader { geometry in
      let cellWidth = max(0, geometry.size.width / 7)
      let markerSize = min(markerDiameter, min(64, max(0, cellWidth - 6)))
      HStack(spacing: 0) {
        ForEach(1...7, id: \.self) { day in
          dayToggle(day, cellWidth: cellWidth, markerSize: markerSize)
        }
      }
    }
    .frame(height: stripHeight)
  }

  private func dayToggle(_ day: Int, cellWidth: CGFloat, markerSize: CGFloat) -> some View {
    let days = component.selectedWeekdays(start: start, calendar: calendar)
    let isLastSelection = days.count == 1 && days.contains(day)
    return Toggle(isOn: weekdayBinding(day)) {
      weekdayMarker(day, size: markerSize, selected: days.contains(day))
        .frame(width: cellWidth, height: stripHeight)
        .contentShape(Rectangle())
    }
    .toggleStyle(.button)
    .buttonStyle(.plain)
    .accessibilityLabel(fullNames[day - 1])
    .accessibilityHint(
      isLastSelection ? "Keep at least one day selected." : "Repeat on this day every week.")
  }

  private func weekdayBinding(_ day: Int) -> Binding<Bool> {
    Binding(
      get: { component.selectedWeekdays(start: start, calendar: calendar).contains(day) },
      set: { selected in
        var days = Set(component.selectedWeekdays(start: start, calendar: calendar))
        if selected { days.insert(day) } else { days.remove(day) }
        guard !days.isEmpty else { return }
        var updated = component
        updated.recurrence = .weekly
        updated.recurrenceWeekdays = days.sorted()
        component = updated
        AppHaptics.selection()
      })
  }

  private func weekdayMarker(_ day: Int, size: CGFloat, selected: Bool) -> some View {
    let shape =
      dynamicTypeSize.isAccessibilitySize
      ? AnyShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
      : AnyShape(Circle())
    return Text(shortNames[day - 1])
      .font(.system(.body, design: .rounded, weight: .semibold))
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      .padding(4)
      .frame(width: size, height: size)
      .foregroundStyle(selected ? Color.accentColor : Color.primary)
      .background(
        selected ? Color.accentColor.opacity(0.18) : Color(uiColor: .tertiarySystemFill), in: shape
      )
      .overlay {
        shape.stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
      }
  }
}

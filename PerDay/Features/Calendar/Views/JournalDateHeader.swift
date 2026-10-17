import SwiftUI

/// Fixed date navigation; horizontal swipes switch the day.
struct JournalDateHeader: View {
  @Binding var selectedDate: Date
  let canDelete: Bool
  let isDeleting: Bool
  let onDelete: () -> Void
  let onFinishDeletion: () -> Void
  let onOpenCalendar: () -> Void
  @State private var showingDatePicker: Bool = false

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      datePickerButton
      Spacer(minLength: 8)
      if AppPlatform.isMac { desktopDateNavigation }
      journalActions
    }
    .padding(.horizontal, JournalStyle.margin).padding(.vertical, JournalStyle.spacing)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var datePickerButton: some View {
    Button {
      onOpenCalendar()
      showingDatePicker = true
    } label: {
      dateLabel
    }
    .buttonStyle(.glass).buttonBorderShape(.capsule)
    .accessibilityHint("Opens the calendar to select a date")
    .popover(isPresented: $showingDatePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
      datePickerPopover
    }
  }

  private var dateLabel: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(selectedDate, format: .dateTime.weekday(.wide)).font(.subheadline).foregroundStyle(
        .secondary)
      Text(selectedDate, format: .dateTime.month(.wide).day().year())
        .font(.headline).fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 12).padding(.vertical, 4).frame(minHeight: 44, alignment: .leading)
  }

  private var datePickerPopover: some View {
    DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
      .datePickerStyle(.graphical).labelsHidden().frame(width: 320).padding(8)
      .presentationCompactAdaptation(.popover)
      .onChange(of: selectedDate) { _, _ in
        AppHaptics.selection()
        showingDatePicker = false
      }
  }

  private var desktopDateNavigation: some View {
    HStack(spacing: 8) {
      Button {
        moveDay(-1)
      } label: {
        Image(systemName: "chevron.left")
      }
      .accessibilityLabel("Previous day").keyboardShortcut(.leftArrow, modifiers: .command)
      .help("Previous day (⌘←)")
      Button("Today") { selectedDate = Calendar.current.startOfDay(for: .now) }
        .keyboardShortcut("t", modifiers: .command).help("Go to today (⌘T)")
      Button {
        moveDay(1)
      } label: {
        Image(systemName: "chevron.right")
      }
      .accessibilityLabel("Next day").keyboardShortcut(.rightArrow, modifiers: .command)
      .help("Next day (⌘→)")
    }
    .buttonStyle(.bordered)
  }

  private var journalActions: some View {
    HStack(spacing: 8) {
      if isDeleting { finishDeletionButton }
      journalSettingsMenu
    }
    .frame(width: isDeleting ? 120 : 56)
  }

  private var finishDeletionButton: some View {
    Button(action: onFinishDeletion) {
      Image(systemName: "checkmark").font(.title3).frame(width: 56, height: 56).contentShape(
        Circle())
    }
    .buttonStyle(.plain).glassEffect(.regular.tint(.accentColor).interactive(), in: Circle())
    .accessibilityLabel("Done deleting").keyboardShortcut(.cancelAction)
  }

  private var journalSettingsMenu: some View {
    Menu {
      if isDeleting {
        Button("Done deleting", systemImage: "checkmark", action: onFinishDeletion)
      } else {
        Button("Delete mode", systemImage: "trash", role: .destructive, action: onDelete).disabled(
          !canDelete)
      }
    } label: {
      Image(systemName: "gearshape").font(.title3).frame(width: 56, height: 56).contentShape(
        Circle())
    }
    .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
    .accessibilityLabel("Journal settings")
  }

  private func moveDay(_ offset: Int) {
    guard let day = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) else {
      return
    }
    AppPlatform.endEditing()
    selectedDate = Calendar.current.startOfDay(for: day)
  }
}

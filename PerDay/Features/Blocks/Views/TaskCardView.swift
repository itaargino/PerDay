import SwiftUI

struct TaskCardView: View {
  let block: NoteBlockModel
  let completionDay: Date
  let onToggleAll: () -> Void
  let onToggleItem: (UUID) -> Void
  let onSaveItems: ([TaskDraft]) -> Bool

  @State private var isEditing: Bool = false
  @State private var editingTasks: [TaskDraft] = []
  @State private var initialFocus: UUID?
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  private var completedCount: Int {
    block.checklist.filter { $0.isCompleted(on: completionDay) }.count
  }

  private var completed: Bool { completedCount == block.checklist.count }
  private var canSave: Bool {
    editingTasks.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      if isEditing {
        TaskListEditor(tasks: $editingTasks, initialFocus: initialFocus)
        Divider()
        taskEditorActions
      } else {
        checklistContent
        addTaskButton
      }
    }
    .journalCard()
  }

  @ViewBuilder
  private var taskEditorActions: some View {
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

  private var checklistContent: some View {
    VStack(spacing: 0) {
      ForEach(block.checklist) { item in
        taskRow(item)
        if item.id != block.checklist.last?.id {
          Divider().padding(.leading, JournalStyle.touchTarget)
        }
      }
    }
  }

  private var addTaskButton: some View {
    Button {
      startEditing(addingTask: true)
    } label: {
      Label("Add a task", systemImage: "plus").font(.body)
        .frame(maxWidth: .infinity, minHeight: JournalStyle.touchTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(JournalRowButtonStyle()).foregroundStyle(Color.accentColor)
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(isEditing ? "Edit tasks" : "Tasks").font(.headline)
        if !isEditing {
          Text("\(completedCount) of \(block.checklist.count) completed").font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 8)
      if !isEditing { taskActionsMenu }
    }
  }

  private var taskActionsMenu: some View {
    Menu {
      Button("Edit tasks", systemImage: "pencil") { startEditing() }
      Button(
        completed ? "Reopen all tasks" : "Complete all tasks",
        systemImage: completed ? "arrow.uturn.backward" : "checkmark.circle", action: onToggleAll)
    } label: {
      Image(systemName: "ellipsis").font(.body.weight(.semibold))
        .frame(width: JournalStyle.touchTarget, height: JournalStyle.touchTarget)
        .contentShape(Rectangle())
    }
    .accessibilityLabel("Task list actions")
  }

  private func taskRow(_ item: TaskItem) -> some View {
    HStack(alignment: .top, spacing: 0) {
      taskCompletionButton(item)
      taskEditButton(item)
    }
  }

  private func taskCompletionButton(_ item: TaskItem) -> some View {
    let finished = item.isCompleted(on: completionDay)
    return Button {
      onToggleItem(item.id)
    } label: {
      Image(systemName: finished ? "checkmark.circle.fill" : "circle")
        .font(.title3)
        .foregroundStyle(finished ? Color.accentColor : Color.secondary)
        .frame(width: JournalStyle.touchTarget, height: JournalStyle.touchTarget)
        .contentShape(Rectangle())
    }
    .buttonStyle(JournalRowButtonStyle())
    .accessibilityLabel(item.text)
    .accessibilityValue(finished ? "Completed" : "Incomplete")
    .accessibilityHint(finished ? "Mark incomplete" : "Mark completed")
  }

  private func taskEditButton(_ item: TaskItem) -> some View {
    let finished = item.isCompleted(on: completionDay)
    return Button {
      startEditing(focusing: item.id)
    } label: {
      Text(item.text)
        .font(.body)
        .strikethrough(finished)
        .foregroundStyle(finished ? Color.secondary : Color.primary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: JournalStyle.touchTarget, alignment: .leading)
        .contentShape(Rectangle())
    }
    .buttonStyle(JournalRowButtonStyle())
    .accessibilityLabel("Edit \(item.text)")
  }

  private var saveButton: some View {
    Button("Save") {
      if onSaveItems(editingTasks) { isEditing = false }
    }
    .buttonStyle(.borderedProminent)
    .disabled(!canSave)
  }

  private var cancelButton: some View {
    Button("Cancel") {
      AppHaptics.tap()
      isEditing = false
    }
    .buttonStyle(.bordered)
  }

  private func startEditing(focusing id: UUID? = nil, addingTask: Bool = false) {
    AppHaptics.tap()
    editingTasks = block.checklist.map { TaskDraft(id: $0.id, text: $0.text) }
    if addingTask {
      let newTask = TaskDraft()
      editingTasks.append(newTask)
      initialFocus = newTask.id
    } else {
      initialFocus = id ?? editingTasks.first?.id
    }
    isEditing = true
  }
}

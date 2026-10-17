import SwiftUI

/// One focused line at a time. Return creates a task; text wraps naturally.
struct TaskListEditor: View {
  @Binding var tasks: [TaskDraft]
  var initialFocus: UUID?
  var automaticallyFocus: Bool = true
  var showsInstruction: Bool = true
  @FocusState private var focusedTask: UUID?
  @State private var pendingFocus: UUID?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(tasks) { task in
        editableTaskRow(task)
        if task.id != tasks.last?.id { Divider().padding(.leading, 32) }
      }
      if showsInstruction { returnInstruction }
    }
    .onAppear {
      if tasks.isEmpty { tasks.append(TaskDraft()) }
      if automaticallyFocus { pendingFocus = initialFocus ?? tasks.last?.id }
    }
    .task(id: pendingFocus) { await focusPendingTask() }
  }

  private var returnInstruction: some View {
    Text("Press Return for the next task.").font(.footnote).foregroundStyle(.secondary)
      .padding(.top, 8).fixedSize(horizontal: false, vertical: true)
  }

  private func editableTaskRow(_ task: TaskDraft) -> some View {
    HStack(alignment: .top, spacing: 4) {
      Image(systemName: "circle").foregroundStyle(.tertiary)
        .frame(width: 28, height: JournalStyle.touchTarget).accessibilityHidden(true)
      taskTextField(task)
      removeTaskButton(task)
    }
  }

  private func taskTextField(_ task: TaskDraft) -> some View {
    TextField("What needs to get done?", text: textBinding(for: task.id), axis: .vertical)
      .font(.body).lineLimit(1...).padding(.vertical, 10)
      .focused($focusedTask, equals: task.id).submitLabel(.next)
      .onSubmit { insertNext(after: task.id) }
      .accessibilityLabel("Task description").accessibilityHint("Return adds another task")
  }

  private func removeTaskButton(_ task: TaskDraft) -> some View {
    Button(role: .destructive) {
      remove(task.id)
    } label: {
      Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
        .frame(width: JournalStyle.touchTarget, height: JournalStyle.touchTarget)
        .contentShape(Rectangle())
    }
    .buttonStyle(JournalRowButtonStyle()).opacity(focusedTask == task.id ? 1 : 0)
    .allowsHitTesting(focusedTask == task.id).accessibilityHidden(focusedTask != task.id)
    .accessibilityLabel("Remove task")
  }

  private func focusPendingTask() async {
    guard let id = pendingFocus else { return }
    // Let SwiftUI install the new row before moving keyboard focus.
    await Task.yield()
    guard !Task.isCancelled, tasks.contains(where: { $0.id == id }) else { return }
    focusedTask = id
    pendingFocus = nil
  }

  private func textBinding(for id: UUID) -> Binding<String> {
    Binding(
      get: { tasks.first(where: { $0.id == id })?.text ?? "" },
      set: { value in
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        if value.contains("\n") || value.contains("\r") {
          splitLines(value, in: id)
        } else {
          tasks[index].text = value
        }
      }
    )
  }

  private func insertNext(after id: UUID) {
    guard pendingFocus == nil, focusedTask == id,
      let index = tasks.firstIndex(where: { $0.id == id })
    else { return }
    guard !tasks[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    let next = index + 1
    if next < tasks.count
      && tasks[next].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      pendingFocus = tasks[next].id
    } else {
      let task = TaskDraft()
      tasks.insert(task, at: next)
      pendingFocus = task.id
      AppHaptics.selection()
    }
  }

  private func splitLines(_ value: String, in id: UUID) {
    guard value.contains("\n") || value.contains("\r"),
      let index = tasks.firstIndex(where: { $0.id == id })
    else { return }
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      tasks[index].text = ""
      return
    }
    let split = TaskLineSplit(value)
    var updated = tasks
    updated[index].text = split.firstLine
    let additions = split.additionalTasks
    updated.insert(contentsOf: additions, at: index + 1)
    tasks = updated
    pendingFocus = additions.last?.id ?? id
    if !additions.isEmpty { AppHaptics.selection() }
  }

  private func remove(_ id: UUID) {
    guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
    var updated = tasks
    updated.remove(at: index)
    if updated.isEmpty { updated.append(TaskDraft()) }
    pendingFocus = updated[min(index, updated.count - 1)].id
    tasks = updated
    AppHaptics.tap()
  }
}

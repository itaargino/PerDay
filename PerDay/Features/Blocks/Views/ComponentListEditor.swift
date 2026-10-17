import SwiftUI

/// Bind by identity, never by an index that can become stale after removal/reorder.
struct ComponentListEditor: View {
  @Binding var components: [JournalComponent]
  let defaultDate: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(components) { component in
        componentRow(component)
        if component.id != components.last?.id { Divider() }
      }
      .reorderable()
      addComponentMenu
    }
    .reorderContainer(for: JournalComponent.self) { applyReorder($0) }
  }

  private func componentRow(_ component: JournalComponent) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 8) {
        reorderMarker(component)
        componentEditor(component)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
        componentActions(component)
      }
      if component.kind == .recurrence {
        RecurrenceEditor(component: componentBinding(component), start: defaultDate)
          .recurrenceDetails
      }
    }
  }

  private func reorderMarker(_ component: JournalComponent) -> some View {
    Image(systemName: "line.3.horizontal")
      .foregroundStyle(.tertiary).frame(width: 44, height: 44).contentShape(Rectangle())
      .accessibilityLabel("Reorder \(component.kind.title) component")
      .accessibilityAction(named: "Move up") { move(component.id, by: -1) }
      .accessibilityAction(named: "Move down") { move(component.id, by: 1) }
  }

  @ViewBuilder
  private func componentEditor(_ component: JournalComponent) -> some View {
    switch component.kind {
    case .text:
      TextField("Write here…", text: binding(component, \.text), axis: .vertical)
        .lineLimit(1...).padding(.vertical, 10)
    case .startDate, .startTime: componentDatePicker(component)
    case .recurrence:
      RecurrenceEditor(component: componentBinding(component), start: defaultDate).recurrencePicker
    case .taskList:
      TaskListEditor(
        tasks: taskBinding(component),
        automaticallyFocus: components.last(where: { $0.kind == .taskList })?.id == component.id,
        showsInstruction: false)
    }
  }

  private func componentDatePicker(_ component: JournalComponent) -> some View {
    DatePicker(
      component.kind.title, selection: binding(component, \.date),
      displayedComponents: component.kind == .startDate ? .date : .hourAndMinute
    )
    .frame(minHeight: 44)
  }

  private func componentActions(_ component: JournalComponent) -> some View {
    Menu {
      Button("Move up", systemImage: "arrow.up") { move(component.id, by: -1) }
        .disabled(components.first?.id == component.id)
      Button("Move down", systemImage: "arrow.down") { move(component.id, by: 1) }
        .disabled(components.last?.id == component.id)
      Button("Remove component", systemImage: "trash", role: .destructive) {
        components.removeAll { $0.id == component.id }
        AppHaptics.tap()
      }
    } label: {
      Image(systemName: "ellipsis").frame(width: 44, height: 44)
    }
    .accessibilityLabel("\(component.kind.title) component actions")
  }

  private var addComponentMenu: some View {
    Menu {
      ForEach(ComponentKind.allCases) { kind in
        Button(kind.title, systemImage: kind.symbol) {
          components.append(JournalComponent(kind: kind, date: defaultDate))
          AppHaptics.selection()
        }
        .disabled(kind.isUnique && components.contains { $0.kind == kind })
      }
    } label: {
      AddComponentPlaceholder()
    }
    .buttonStyle(.plain)
  }

  private func componentBinding(_ value: JournalComponent) -> Binding<JournalComponent> {
    Binding(
      get: { components.first(where: { $0.id == value.id }) ?? value },
      set: { update in
        guard let index = components.firstIndex(where: { $0.id == value.id }) else { return }
        components[index] = update
      })
  }

  private func binding<Value>(
    _ value: JournalComponent, _ path: WritableKeyPath<JournalComponent, Value>
  ) -> Binding<Value> {
    Binding(
      get: { (components.first(where: { $0.id == value.id }) ?? value)[keyPath: path] },
      set: { update in
        guard let index = components.firstIndex(where: { $0.id == value.id }) else { return }
        components[index][keyPath: path] = update
      })
  }

  private func taskBinding(_ value: JournalComponent) -> Binding<[TaskDraft]> {
    Binding(
      get: {
        (components.first(where: { $0.id == value.id }) ?? value).tasks.map {
          TaskDraft(id: $0.id, text: $0.text)
        }
      },
      set: { tasks in
        guard let index = components.firstIndex(where: { $0.id == value.id }) else { return }
        let previous = components[index].tasks
        components[index].tasks = tasks.map { $0.preservingHistory(in: previous) }
      })
  }

  private func applyReorder(
    _ difference: ReorderDifference<UUID, ReorderableSingleCollectionIdentifier>
  ) {
    let sourceIDs = Set(difference.sources)
    let moving = components.filter { sourceIDs.contains($0.id) }
    guard !moving.isEmpty else { return }
    var reordered = components.filter { !sourceIDs.contains($0.id) }
    let destination: Int
    switch difference.destination.position {
    case .before(let id):
      guard let index = reordered.firstIndex(where: { $0.id == id }) else { return }
      destination = index
    case .end:
      destination = reordered.endIndex
    }
    reordered.insert(contentsOf: moving, at: destination)
    guard reordered.map(\.id) != components.map(\.id) else { return }
    components = reordered
    AppHaptics.selection()
  }

  private func move(_ id: UUID, by offset: Int) {
    guard let index = components.firstIndex(where: { $0.id == id }),
      components.indices.contains(index + offset)
    else { return }
    components.swapAt(index, index + offset)
    AppHaptics.selection()
  }
}

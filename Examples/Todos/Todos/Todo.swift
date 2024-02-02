import ComposableArchitecture
import SwiftUI
import TCAComposer

@ComposeReducer(.bindable)
@Composer
struct Todo {
  struct State: Equatable, Identifiable {
    var description = ""
    let id: UUID
    var isComplete = false
  }
}

struct TodoView: View {
  @Bindable var store: StoreOf<Todo>

  var body: some View {
    HStack {
      Button {
        store.isComplete.toggle()
      } label: {
        Image(systemName: store.isComplete ? "checkmark.square" : "square")
      }
      .buttonStyle(.plain)

      TextField("Untitled Todo", text: $store.description)
    }
    .foregroundColor(store.isComplete ? .gray : nil)
  }
}

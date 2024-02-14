import ComposableArchitecture

import TCAComposer

// @Composer smoke test for compilation issues

@Composer
struct Counter {
  struct State: Equatable {
    var count = 0
  }
}


// MARK: Conformances

@ComposeReducer(
  .action(.hashable, .equatable, .sendable),
  .state(.codable, .hashable, .sendable)
)
@Composer
struct FullyConformed {
}

// MARK: Existing State and Action

@ComposeReducer(
  children: [
    .reducer("counter", of: Counter.self)
  ]
)
@Composer
struct CounterParentWithExistingStateAndAction {
  @ObservableState
  struct State {
  }
  
  enum Action {
    @ComposeAllCasePaths
    struct AllCasePaths {}
  }
}

// MARK: Alerts and Confirmation Dialogs

@ComposeReducer(
  children: [
    .presentsAlert()
  ]
)
@Composer
struct PresentsAlertReducer {
  
  @ComposeActionAlertCase
  enum AlertAction {
    case confirmDelete
  }
  
  @ComposeBody(action: \Action.Cases.alert.confirmDelete)
  func handleAlert() {}
  
}

@ComposeReducer(
  children: [
    .presentsConfirmationDialog()
  ]
)
@Composer
struct PresentsConfirmationDialogReducer {
  
  @ComposeActionConfirmationDialogCase
  enum ConfirmationDialogAction {
    case confirmDelete
  }
  
  @ComposeBody(action: \Action.Cases.confirmationDialog.confirmDelete)
  func handleConfirmationDialog() {}
}


// MARK: Navigation Destination

@ComposeReducer(
  children: [
    .presentsDestination(
      children: [
        .reducer("counter1", of: Counter.self),
        .reducer("counter2", of: Counter.self, initialState: .init()),
        .state("someState", of: String.self),
        .state("someOtherState", of: String.self, initialValue: "foo"),
        .state("tupleState", of: (Int, String).self),
        .stateless("emptyState")
      ]
    )
  ]
)
@Composer
struct NavigationDestinationReducer {
}


// MARK: Navigation Stack

@ComposeReducer(
  children: [
    .navigationStack(
      children: [
        .reducer("counter1", of: Counter.self),
        .reducer("counter2", of: Counter.self, initialState: .init()),
        .state("someState", of: String.self),
        .state("someOtherState", of: String.self, initialValue: "foo"),
        .state("tupleState", of: (Int, String).self),
        .stateless("emptyState")
      ]
    )
  ]
)
@Composer
struct NavigationStackReducer {
}

// MARK: Enum Reducers

@ComposeEnumReducer(
  children: [
    .reducer("counter1", of: Counter.self),
    .reducer("counter2", of: Counter.self, initialState: .init()),
    .state("someState", of: String.self),
    .state("someOtherState", of: String.self, initialValue: "foo"),
    .state("tupleState", of: (Int, String).self),
    .stateless("emptyState")
  ]
)
@Composer
struct EnumeratedComplexReducer {
}

@ComposeEnumReducer(
  children: [
    .reducer("counter1", of: Counter.self),
    .reducer("counter2", of: Counter.self, initialState: .init()),
    .state("someState", of: String.self),
    .state("someOtherState", of: String.self, initialValue: "foo"),
    .state("tupleState", of: (Int, String).self),
    .stateless("emptyState")
  ]
)
@Composer
struct EnumeratedComplexIfCaseLetReducer {
  @ComposeBody
  func reduce() -> EffectOf<Self> {
    return .none
  }
}

@ComposeEnumReducer(
  .initialStateCase("counter"),
  children: [
    .reducer("counter", of: Counter.self, initialState: .init())
  ]
)
@Composer
struct EnumeratedReducerInitialStateCounter {
}

@ComposeEnumReducer(
  .initialStateCase("loading"),
  children: [
    .stateless("loading")
  ]
)
@Composer
struct EnumeratedReducerDefaultStateless {
}

import ComposableArchitecture

extension Store
where
  State: ScopeSwitchable,
  State.AllComposedScopeCases.State == State,
  State.AllComposedScopeCases.Action == Action
{

  /// Returns an enum of `ScopedState` from a `Store` when the `State` conforms to ``ScopeSwitchable``.
  /// Composer automatically conforms `State` to ``ScopeSwitchable`` when the `State` is an enum or when
  /// generating a `Reducer` for a navigation stack.
  ///
  /// This allows for a more concise way of creating views that use enumerated `State`.
  ///
  /// For example, it allows one to write:
  /// ```swift
  /// var body: some View {
  ///  NavigationStack(path: $store.scopes(\.path)) {
  ///    SyncUpsListView(store: store.scopes.syncUpsList)
  ///  } destination: { store in
  ///    switch store.cases {
  ///    case let .detail(store):
  ///      SyncUpDetailView(store: store)
  ///    case let .meeting(meeting, syncUp: syncUp):
  ///      MeetingView(meeting: meeting, syncUp: syncUp)
  ///    case let .record(store):
  ///      RecordMeetingView(store: store)
  ///    }
  ///  }
  ///}
  /// ```
  ///
  /// Instead of the more verbose:
  ///
  /// ```swift
  ///var body: some View {
  ///  NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
  ///    SyncUpsListView(
  ///      store: store.scope(state: \.syncUpsList, action: \.syncUpsList)
  ///    )
  ///  } destination: { store in
  ///    switch store.state {
  ///    case .detail:
  ///      if let store = store.scope(state: \.detail, action: \.detail) {
  ///        SyncUpDetailView(store: store)
  ///      }
  ///    case let .meeting(meeting, syncUp: syncUp):
  ///      MeetingView(meeting: meeting, syncUp: syncUp)
  ///    case .record:
  ///      if let store = store.scope(state: \.record, action: \.record) {
  ///        RecordMeetingView(store: store)
  ///      }
  ///    }
  ///  }
  ///}
  /// ```
  ///
  /// > Note: Generated navigation destination reducers created using `.presentsDestination()` are always ``ScopePathable``
  /// rather than ``ScopeSwitchable`` to support scoping to bindings to be used in presentation modifiers in SwiftUI views.
  ///
  public var `case`: State.AllComposedScopeCases.ScopedState {
    return State.AllComposedScopeCases.scopedState(store: self)
  }
}

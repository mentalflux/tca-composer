import ComposableArchitecture

// A stucture to provide scopes via dynamic member lookup of `ScopePathable` State.
@dynamicMemberLookup
public struct ComposedScopeStores<State: ScopePathable, Action> {
  let store: Store<State, Action>

  @MainActor
  public subscript<ChildState, ChildAction>(
    dynamicMember keyPath: ScopeKeyPath<State, ChildState, Action, ChildAction>
  ) -> Store<ChildState, ChildAction> {
    let keyPath = State.allComposedScopePaths[keyPath: keyPath]
    return store.scope(state: keyPath.state, action: keyPath.action)
  }

  /// Scopes the store to optional child state and actions.
  ///
  /// If your feature holds onto a child feature as an optional:
  ///
  /// ```swift
  /// @Composer
  /// @Reducer
  /// struct Feature {
  ///   @ObservableState
  ///   struct State {
  ///     var child: Child.State?
  ///     // ...
  ///   }
  ///   enum Action {
  ///     case child(Child.Action)
  ///     // ...
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// …then you can use this `scopes` operator in order to transform a store of your feature into
  /// a non-optional store of the child domain:
  ///
  /// ```swift
  /// if let childStore = store.scopes.child {
  ///   ChildView(store: childStore)
  /// }
  /// ```
  ///
  /// > Important: This operation should only be used from within a SwiftUI view or within
  /// > `withPerceptionTracking` in order for changes of the optional state to be properly observed.
  ///
  /// - Parameters:
  ///   - state: A key path to optional child state.
  ///   - action: A case key path to child actions.
  /// - Returns: An optional store of non-optional child state and actions.
  @MainActor
  public subscript<ChildState, ChildAction>(
    dynamicMember keyPath: ScopeKeyPath<State, ChildState?, Action, ChildAction>
  ) -> Store<ChildState, ChildAction>? {
    let scopePaths = State.allComposedScopePaths[keyPath: keyPath]
    return store.scope(state: scopePaths.state, action: scopePaths.action)
  }

  @_disfavoredOverload
  @MainActor
  public subscript<ElementID, ElementState, ElementAction>(
    dynamicMember keyPath: ScopeKeyPath<
      State, IdentifiedArray<ElementID, ElementState>, Action,
      IdentifiedAction<ElementID, ElementAction>
    >
  ) -> some RandomAccessCollection<Store<ElementState, ElementAction>> {
    let scopePath = State.allComposedScopePaths[keyPath: keyPath]
    return store.scope(state: scopePath.state, action: scopePath.action)
  }
}

extension Store where State: ScopePathable {
  /// Provides ergonomic access to scopes using dynamic member lookup of `State` when it conforms to ``ScopePathable``.
  public var scopes: ComposedScopeStores<State, Action> { ComposedScopeStores(store: self) }

}

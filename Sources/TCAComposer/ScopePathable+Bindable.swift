@_spi(Internals) import ComposableArchitecture
import SwiftUI

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
extension SwiftUI.Bindable {

  // TODO: Determine if there is a way to get auto-complete working using this approach.
  // public var dmlScopes: BindableComposedScopes<Value> { BindableComposedScopes(store: self.wrappedValue) }

  public func scopes<State: ScopePathable, Action, ChildState, ChildAction>(
    _ scopeKeyPath: ScopeKeyPath<State, ChildState?, Action, PresentationAction<ChildAction>>
  ) -> Binding<Store<ChildState, ChildAction>?>
  where Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }

  public func scopes<State: ScopePathable, Action, ElementState, ElementAction>(
    _ scopeKeyPath: ScopeKeyPath<
      State, StackState<ElementState>, Action, StackAction<ElementState, ElementAction>
    >
  ) -> Binding<Store<StackState<ElementState>, StackAction<ElementState, ElementAction>>>
  where Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }
}

#if !os(visionOS)

@available(iOS, introduced: 13, obsoleted: 17)
@available(macOS, introduced: 10.15, obsoleted: 14)
@available(tvOS, introduced: 13, obsoleted: 17)
@available(watchOS, introduced: 6, obsoleted: 10)
@available(visionOS, unavailable)
extension Perception.Bindable {

  @available(visionOS, unavailable)
  public func scopes<State, ChildState, Action, ChildAction>(
    _ scopeKeyPath: ScopeKeyPath<State, ChildState?, Action, PresentationAction<ChildAction>>
  ) -> Binding<Store<ChildState, ChildAction>?>
  where State: ObservableState & ScopePathable, Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }

  @available(visionOS, unavailable)
  public func scopes<State: ScopePathable, Action, ElementState, ElementAction>(
    _ scopeKeyPath: ScopeKeyPath<
    State,
    StackState<ElementState>,
    Action,
    StackAction<ElementState, ElementAction>
    >
  ) -> Binding<Store<StackState<ElementState>, StackAction<ElementState, ElementAction>>>
  where Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }
}
#endif

extension Binding {
  public func scopes<State: ObservableState, Action, ChildState, ChildAction>(
    _ scopeKeyPath: ScopeKeyPath<State, ChildState?, Action, PresentationAction<ChildAction>>
    //      state: KeyPath<State, ChildState?>,
    //      action: CaseKeyPath<Action, PresentationAction<ChildAction>>
  ) -> Binding<Store<ChildState, ChildAction>?> where Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }

  public func scopes<State: ScopePathable, Action, ElementState, ElementAction>(
    _ scopeKeyPath: ScopeKeyPath<
      State, StackState<ElementState>, Action, StackAction<ElementState, ElementAction>
    >
  ) -> Binding<Store<StackState<ElementState>, StackAction<ElementState, ElementAction>>>
  where Value == Store<State, Action> {
    let scopePath = State.allComposedScopePaths[keyPath: scopeKeyPath]
    return self.scope(state: scopePath.state, action: scopePath.action)
  }
}


#if false
// TODO: Investigate why auto-complete doesn't work when using this approach.
@dynamicMemberLookup
public struct BindableComposedScopes<Value> {
  let store: Value

  public subscript<State: ScopePathable, Action, ChildState, ChildAction>(
    dynamicMember keyPath: ScopeKeyPath<State, ChildState?, Action, PresentationAction<ChildAction>>
  ) -> Binding<Store<ChildState, ChildAction>?> where Value == Store<State, Action> {
    Binding<Store<ChildState, ChildAction>?>(
      get: {
        let scopePaths = State.allComposedScopePaths[keyPath: keyPath]
        return store.scope(
          state: scopePaths.state, action: scopePaths.action.appending(path: \.presented))
      },
      set: {
        let scopePaths = State.allComposedScopePaths[keyPath: keyPath]
        if $0 == nil, store.currentState[keyPath: scopePaths.state] != nil {
          store.send(scopePaths.action(.dismiss), transaction: $1)
        }
      }
    )
  }

  public subscript<State: ScopePathable, Action, ElementState, ElementAction>(
    dynamicMember keyPath: ScopeKeyPath<
      State, StackState<ElementState>, Action, StackAction<ElementState, ElementAction>
    >
  ) -> Binding<Store<StackState<ElementState>, StackAction<ElementState, ElementAction>>>
  where Value == Store<State, Action> {
    Binding<Store<StackState<ElementState>, StackAction<ElementState, ElementAction>>>(
      get: {
        let scopePaths = State.allComposedScopePaths[keyPath: keyPath]
        return store.scope(state: scopePaths.state, action: scopePaths.action)
      },
      set: { _ in }
    )
  }
}
#endif

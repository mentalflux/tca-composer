import ComposableArchitecture

/// Provides support for implementing the ``ComposableArchitecture/Store/cases`` extension to ``ComposableArchitecture/Store``
/// which provides better ergonomics when working with enumerated  `State`.
///
/// > Note: Composer automatically provides conformance if needed during macro expansion. Developers should not attempt to provide their own conformance.
public protocol ScopeSwitchable: ObservableState {
  associatedtype AllComposedScopeCases: ScopeCases

  static var allComposedScopeCases: AllComposedScopeCases { get }
}

public protocol ScopeCases<State, Action> {
  associatedtype State: ObservableState
  associatedtype Action
  associatedtype ScopedState

  static func scopedState(store: Store<State, Action>) -> ScopedState
}

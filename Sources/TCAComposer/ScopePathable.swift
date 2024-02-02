@_spi(Internals) import ComposableArchitecture
import SwiftUI

/// Provides support for implementing the ``ComposableArchitecture/Store/scopes`` extension to ``ComposableArchitecture/Store``
/// which provides better ergonomics for scoping `State` in SwiftUI Views.
///
/// > Note: Composer automatically provides conformance if needed during macro expansion. Developers should not attempt to provide their own conformance.
public protocol ScopePathable: ObservableState {
  associatedtype AllComposedScopePaths

  static var allComposedScopePaths: AllComposedScopePaths { get }
}

/// Represents a key path pair to a scope of a `Store`.
public struct ScopePath<State, ChildState, Action, ChildAction> {

  @usableFromInline
  let state: KeyPath<State, ChildState>

  @usableFromInline
  let action: CaseKeyPath<Action, ChildAction>

  @inlinable
  public init(
    state: KeyPath<State, ChildState>,
    action: CaseKeyPath<Action, ChildAction>
  ) {
    self.state = state
    self.action = action
  }
}

public typealias ScopeKeyPath<State: ScopePathable, ChildState, Action, ChildAction> =
  KeyPath<State.AllComposedScopePaths, ScopePath<State, ChildState, Action, ChildAction>>

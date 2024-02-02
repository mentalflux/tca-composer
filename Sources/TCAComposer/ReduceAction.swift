import ComposableArchitecture

/// A Reducer that reduces a child action, used by ``Composer()`` when constructing the `Reducer.body`
@Reducer
public struct ReduceAction<State, Action, ChildAction> {

  @usableFromInline
  let toChildAction: AnyCasePath<Action, ChildAction>

  @usableFromInline
  let reduceChildAction: (inout State, ChildAction) -> Effect<Action>

  /// Initialized a reducer that reduces `ChildAction` to `Effect<Action>`
  /// - Parameters:
  ///   - toChildAction: A `CaseKeyPath` to the `ChildAction`
  ///   - reduceChildAction: A closure that reduces `ChildAction` to `Effect<Action>`
  @inlinable
  public init(
    _ toChildAction: CaseKeyPath<Action, ChildAction>,
    reduceChildAction: @escaping (inout State, ChildAction) -> Effect<Action>
  ) {
    self.toChildAction = AnyCasePath(toChildAction)
    self.reduceChildAction = reduceChildAction
  }

  @inlinable
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    guard let childAction = self.toChildAction.extract(from: action) else {
      return .none
    }
    return reduceChildAction(&state, childAction)
  }
}

@Reducer
public struct ReduceIdentifiedAction<State, Action, ElementID: Hashable, ChildAction, ElementAction>
{

  @usableFromInline
  let toIdentifiedAction: AnyCasePath<Action, IdentifiedAction<ElementID, ChildAction>>

  @usableFromInline
  let toElementAction: AnyCasePath<ChildAction, ElementAction>

  @usableFromInline
  let reduceChildAction: (inout State, ElementID, ElementAction) -> Effect<Action>

  /// Initialized a reducer that reduces `ChildAction` to `Effect<Action>`
  /// - Parameters:
  ///   - toIdentifiedAction: A `CaseKeyPath` to the `IdentifiedAction<ElementID, ChildAction>>`
  ///   - toElementAction: A `CaseKeyPath` to the `ElementAction`
  ///   - reduceChildAction: A closure that reduces `ChildAction` to `Effect<Action>`
  @inlinable
  public init(
    _ toIdentifiedAction: CaseKeyPath<Action, IdentifiedAction<ElementID, ChildAction>>,
    element toElementAction: CaseKeyPath<ChildAction, ElementAction>,
    reduceChildAction: @escaping (inout State, ElementID, ElementAction) -> Effect<Action>
  ) {
    self.toIdentifiedAction = AnyCasePath(toIdentifiedAction)
    self.toElementAction = AnyCasePath(toElementAction)
    self.reduceChildAction = reduceChildAction
  }

  @inlinable
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    guard let identifedAction = self.toIdentifiedAction.extract(from: action),
      case let .element(id, childAction) = identifedAction,
      let elementAction = self.toElementAction.extract(from: childAction)
    else {
      return .none
    }
    return reduceChildAction(&state, id, elementAction)
  }
}

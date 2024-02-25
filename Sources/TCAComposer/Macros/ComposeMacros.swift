import ComposableArchitecture
import Foundation
import IdentifiedCollections

/// Attached to a enum declartion. Adds a new case to the `Action` of the `Reducer`.
///
/// - Parameters:
///   - name: The name of the case label to add to `Action`
@attached(peer)
public macro ComposeActionCase(_ name: String = "") =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Specifies the enum to use for the `AlertAction` for an alert declared in a ``ComposeReducer(_:children:)`` child.
///
/// This is an alternative method of declaring alerts
@attached(peer)
public macro ComposeActionAlertCase(_ name: String = "") =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Specifies the enum to use for the `ConfirmationDialogAction` for a confirmation dialog declared in a ``ComposeReducer(_:children:)`` child.
///
/// This is an alternative method of declaring confirmation dialogs
@attached(peer)
public macro ComposeActionConfirmationDialogCase(_ name: String = "") =
#externalMacro(
  module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
)

/// Directs ``Composer()`` to generate `CasePath`s on an existing `Action` enum. The macro should only be attached
/// to an empty `AllCasePaths` struct declaration inside of the `Action`
@attached(peer)
public macro ComposeAllCasePaths() =
#externalMacro(
  module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
)

/// The plaacement options of
public enum ComposerBodyPosition {

  // places inside the "core" reducer
  case core

  // places after the "core" reducer in the order of declaration
  case afterCore

  // Places before the core reducer, after bindable and scopes
  case beforeCore
}

@attached(peer)
public macro ComposeBody<Action, ChildAction>(action: CaseKeyPath<Action, ChildAction>) =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Composes the attached declaration into the `body` of the `Reducer` by using the keypath `action[id: id].elementAction`.
/// This form of `@ComposeBody` is intended to assit in destructuring reducers contained in an `IdentifiedArray`
/// - Parameters:
///   - identifiedAction: The `CaseKeyPath` of an `IdentifiedAction` to decompose.
///   - elementAction: The `CaseKeyPath` of the element of the `IdentifiedAction` to decocmpose
///
/// ```swift
///  @ComposeBody(identifiedAction: \Action.Cases.voiceMemos, elementAction: \.delegate)
///  func voiceMemos(state: inout State, id: VoiceMemo.State.ID, action: VoiceMemo.DelegateAction) -> EffectOf<VoiceMemos> {
///    switch action {
///    case .playbackFailed:
///        state.alert = AlertState { TextState("Voice memo playback failed.") }
///        return .none
///    case .playbackStarted:
///        for memoID in state.voiceMemos.ids where memoID != id {
///            state.voiceMemos[id: memoID]?.mode = .notPlaying
///        }
///    }
/// }
/// ```
@attached(peer)
public macro ComposeBody<
  Action,
  ChildAction,
  ElementID: Hashable,
  ElementAction
>(
  identifiedAction: CaseKeyPath<Action, IdentifiedAction<ElementID, ChildAction>>,
  elementAction: CaseKeyPath<ChildAction, ElementAction>
) =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Composes the attached declaration in the `body` of the `Reducer` at the specified location.
///  - Parameters:
///     - order: The location to place the declaration
///
@attached(peer)
public macro ComposeBody(position: ComposerBodyPosition = .core) =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Adds a new `case` into the Reducer's `Action` enum and calls the attached function from the `body` of the reducer.
///
/// - Parameters:
///   - name: The name of the `case` that will be added to the Reducer's `Action` enum. If not provided the name of the function this macro is attached to will be used.
///
/// This macro is a short hand way of combining two Composer directives of ``ComposeBody(action:)`` and ``ComposeActionCase(_:)``, in a more concise manner.
///
/// ```swift
/// @Composer
/// struct Feature {
///   enum ViewAction {
///     case buttonClicked
///   }
///
///   @ComposeBodyActionCase
///   func view(state: inout State, action: ViewAction) -> EffectOf<Feature> {
///     switch action {
///       case .buttonClicked:
///         // do something
///         return .none
///   }
/// }
/// ```
///
///  The ``ComposeBodyActionCase(_:)`` must be attached to a function. The macro supports several valid method signatures:
///
///  The most complete signature takes a `state` and `action` and returns an effect of `Feature.Action`.  The type of the `action` parameter
///  is used to determine the associated type of the `case` to add to the `Action` enum.
///
///  ```swift
///  @ComposeBodyActionCase
///  func view(state: inout State, action: ViewAction) -> EffectOf<Feature> {
///    switch action {
///       case .buttonClicked:
///         // do something
///         return .none
///    }
///  }
///  ```
///
///  Optionally, one may omit the return type of `EffectOf<Feature>`.  This is the equivalent of always returning `Effect.none` from the method.
///
///  ```swift
///  @ComposeBodyActionCase
///  func view(state: inout State, action: ViewAction) {
///    switch action {
///       case .buttonClicked:
///         // do something with state
///    }
///  }
///  ```
///
/// Alternatively, one may also emit the `state` parameter if access to state is not required for this reduce function. Or, even drop the `inout` modifier
/// to treat `State` as read-only.
///
/// ```swift
///  @ComposeBodyActionCase
///   func view(action: ViewAction) -> EffectOf<Feature> {
///     switch action {
///       case .buttonClicked:
///         return .run { send in
///           // some effect
///         }
///     }
/// }
/// ```
///
/// The only required paramter is `action` which must be provided to determine the type to embed into the `Action` enum.
///
@attached(peer)
public macro ComposeBodyActionCase(_ name: String = "") =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

@attached(peer)
public macro ComposeBodyActionAlertCase(_ name: String = "") =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

/// Specified the location in the `body` to attach the `.onChange()` modifier.
public enum ComposeBodyOnChangeAttachment {
  // Attaches the `.onChange()` modifier to the `BindingReducer`
  case binding
  
  // Attaches the `.onChange()` modifier to the reducer core.
  case core
  
  // Attaches the `.onChange()` modifier to the `Scope` reducer for the specified child.
  case scope(String)
}

/// Adds an `onChange(of: ...)` modifier to the `body` of the Reducer.
/// - Parameters:
///   - of: A `KeyPath` of `State` to use in calling the `.onChange()` modifier
///   - attachment: Specified which Reducer in the `body` to attach the `.onChange()` to. By default it will be attached to the core.
///
@attached(peer)
public macro ComposeBodyOnChange<State, Value>(of keyPath: KeyPath<State, Value>, attachment: ComposeBodyOnChangeAttachment = .core) =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )

#if false
///
/// Overrides the reducer to be use for a child.
///
/// By default a child that is composed into a Reducer, directly uses the child reducer by instantiating it with no aguments. In the example below the default child reducer would be `Feature()`
/// ```swift
/// @CopmoseReducer(
///   children[
///     .reducer("feature", of: Feature.self)
///   ]
/// )
/// @Composer
/// struct Onboarding {
/// }
/// ```
///
/// Expanding the ``Composer()`` macro yields:
///
/// ```swift
/// struct Onboarding {
///   struct State {
///     var feature: Feature.State
///   }
///   enum Action {
///     case feature(Feature.Action)
///   }
///
///   var body: some Reducer<State, Action> {
///     Scope(state: \.feature, action: \.feature) {
///       Feature()
///     }
///   }
/// }
/// ```
///
/// In cases where it is desirable to use a different child reducer, the ``ComposeBodyChildReducer(_:)`` macro may be attched to a variable declaration that returns `some ReducerOf<Feature>`.
///
/// ```swift
/// @CopmoseReducer(
///   children[
///     .reducer("feature", of: Feature.self)
///   ]
/// )
/// @Composer
/// struct Onboarding {
///   @ComposeBodyChildReducer("feature")
///   var featureWithDependencies: some ReducerOf<Feature> {
///     Feature()
///       .dependency(\.apiClient, .mock)
///       .dependency(\.userDefaults, .mock)
///     }
/// }
///  ```
///
/// Expanding the ``Composer()`` macro now yields:
///
/// ```swift
/// struct Onboarding {
///   struct State {
///     var feature: Feature.State
///   }
///   enum Action {
///     case feature(Feature.Action)
///   }
///
///    var featureWithDependencies: some ReducerOf<Feature> {
///       Feature()
///         .dependency(\.apiClient, .mock)
///         .dependency(\.userDefaults, .mock)
///   }
///
///   var body: some Reducer<State, Action> {
///     Scope(state: \.feature, action: \.feature) {
///       self.featureWithDependencies
///     }
///   }
/// }
/// ```
///
@attached(peer)
public macro ComposeBodyChildReducer(_ name: String) =
  #externalMacro(
    module: "TCAComposerMacros", type: "ComposeDirectiveMacro"
  )
#endif

public enum ComposeReducerActionOption {
  case equatable
  case hashable
  case sendable
}

public enum ComposeReducerStateOption {
  case codable
  case hashable
  case notEquatable
  case sendable
}

/// Options that can be used to configure the behavior of ``ComposeReducer(_:children:)``.
public struct ComposeEnumReducerOption {

  /// Customizes  `Action` when it is automatically generated
  public static func action(_ options: ComposeReducerActionOption...) -> Self { Self() }

  /// Generated an initializer for `State` using the specified case `name`
  public static func initialStateCase(_ name: String) -> Self { Self() }

  /// Customizes  `State` when it is automatically generated
  public static func state(_ options: ComposeReducerStateOption...) -> Self { Self() }

  fileprivate init() {}
}

/// A macro for automatically generating a `Reducer`
/// - Parameters:
///    - options: A variadc list of ``ComposeReducerOption`` to change the code generation behavior.
///    - children: An array of ``ComposedReducerChild`` to embed into the `Reducer`
@attached(peer)
public macro ComposeEnumReducer(
  _ options: ComposeEnumReducerOption..., children: [ComposedEnumReducerChild] = []
) =
  #externalMacro(module: "TCAComposerMacros", type: "ComposeDirectiveMacro")

/// Options that can be used to configure the behavior of ``ComposeReducer(_:children:)``.
public struct ComposeReducerOption {

  /// Customizes  `Action` when it is automatically generated
  public static func action(_ options: ComposeReducerActionOption...) -> Self { Self() }

  /// Adds bindable support to the `Reducer` by conforming `Action` to `BindableAction` and adding a `BindingReducer()` to the generated `body`.
  public static let bindable = Self()

  /// Customizes  `State` when it is automatically generated
  public static func state(_ options: ComposeReducerStateOption...) -> Self { Self() }

  fileprivate init() {}
}

/// A macro for automatically generating a `Reducer`
/// - Parameters:
///    - options: A variadc list of ``ComposeReducerOption`` to change the code generation behavior.
///    - children: An array of ``ComposedReducerChild`` to embed into the `Reducer`
@attached(peer)
public macro ComposeReducer(
  _ options: ComposeReducerOption..., children: [ComposedReducerChild] = []
) =
  #externalMacro(module: "TCAComposerMacros", type: "ComposeDirectiveMacro")

/// Creates a custom scope path on a member of `State` paired to a specified action in `Action`
///
/// - Parameters:
///   - action: The `CaseKeyPath` of the `case` that will be paired with the member of `State`
///
/// ```swift
/// @ComposeReducer(
///   children: [
///    .reducer("todos", of: [Todo].self)
///   ]
/// )
/// @Composer
/// struct Todos {
///    struct State {
///      var filter: Filter = .all
///
///      @ComposeScopePath(action: \Action.Cases.todos)
///      var filteredTodos: IdentifiedArrayOf<Todo.State> {
///        switch filter {
///          case .active: return self.todos.filter { !$0.isComplete }
///          case .all: return self.todos
///          case .completed: return self.todos.filter(\.isComplete)
///      }
///   }
/// }
/// ```
/// The above cdoe will create a  ``ScopePath`` that is accessible via the `\.filteredTodos` key path and can be used when create a new scope from a `Store` as follows:
///
/// ```swift
/// List {
///   ForEach(store.scopes.filteredTodos) { store in
///      TodoView(store: store)
///   }
/// }
/// ```
@attached(peer)
public macro ComposeScopePath<Action, ChildAction>(action: CaseKeyPath<Action, ChildAction>) =
  #externalMacro(module: "TCAComposerMacros", type: "ComposeDirectiveMacro")

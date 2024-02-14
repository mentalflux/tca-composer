import ComposableArchitecture

/// Represents a child to be added to a ``ComposeReducer(_:children:)`` macro declaration.  `ComposedReducerChild` cannot be instantiated directly, but should instead by created via one of the avilable static methods defined below.
///
/// ### Reducer Children
/// * ``reducer(_:of:)-vox8`` - Adds a reducer child
/// * ``reducer(_:of:initialState:)-71rhp`` - Adds a reducer child with an initial value for `State`
/// * ``reducer(_:of:)-904p1`` - Adds a reducer child with optional state.
/// * ``reducer(_:of:initialState:)-7adhx`` - Adds a reducer child with optional state and an initial value for `State`
/// 
/// ### Identified Arrays of Reducer Children
/// * ``identifiedArray(_:of:)`` Adds an array of reducer children
/// * ``identifiedArray(_:of:initialState:)`` - Adds an array of reducer children with an initial value for `State`
///
/// ### Presenting Children via Navigation
///  * ``presentsAlert(_:)`` - Created an alert to be presented.
///
public struct ComposedReducerChild {
  fileprivate init() {}
}

extension ComposedReducerChild {
  /// Constructs a `ComposedReducerChild` representing a child reducer.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  /// - Returns: A `ComposedReducerChild` representing a `Reducer`
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// @Composer
  /// struct Child {
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .reducer("child", of: Child.self)
  ///   ]
  /// )
  /// @Composer
  /// struct Parent {
  /// }
  /// ```
  ///
  /// Generates the following output:
  ///
  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  /// Constructs a `ComposedReducerChild` representing a child reducer with an initial state value.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  ///   - initialState: An autoclosure that is used to provide the initial value of the generated child in `State`.
  /// - Returns: A `ComposedReducerChild` representing a child `Reducer`.
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// @Reducer
  /// struct Child {
  ///   // Child reducer code...
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .reducer("child", of: Child.self, initialState: .init())
  ///   ]
  /// )
  /// @Composer
  /// @Reducer
  /// struct Parent {
  /// }
  /// ```
  ///
  /// Generates the following output when the ``Composer()`` macro is expanded.
  ///
  /// ```diff
  ///  @Reducer
  ///  struct Parent {
  /// +  struct State {
  /// +    var child: Child.State = .init()
  /// +  }
  /// +  enum Action {
  /// +    case child(Child.Action)
  /// +  }
  ///  }
  /// ```
  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type,
    initialState: @autoclosure () -> Child.State
  ) -> Self { Self() }

  /// Constructs a `ComposedReducerChild` representing an optional child reducer.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  /// - Returns: A `ComposedReducerChild` representing a `Reducer`
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// @Composer
  /// struct Child {
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .reducer("child", of: Child.self, initialState: .init())
  ///   ]
  /// )
  /// @Composer
  /// struct Parent {
  /// }
  /// ```
  /// Generates the following output:
  ///
  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child?.Type
  ) -> Self { Self() }

  /// Constructs a `ComposedReducerChild` representing an optional child reducer with an initial state value.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  ///   - initialState: An autoclosure that is used to provide the initial value of the generated child in `State`
  /// - Returns: A `ComposedReducerChild` representing a `Reducer`
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// struct Child: Reducer {
  ///   // Child reducer code...
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .reducer("child", of: Child.self, initialState: .init())
  ///   ]
  /// )
  /// @Composer
  /// struct Parent {
  /// }
  /// ```
  /// Generates the following output
  ///
  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child?.Type,
    initialState: @autoclosure () -> Child.State
  ) -> Self { Self() }

  /// Constructs a `ComposedReducerChild` representing an array of child reducer state, respresented by an `IdentifiedArrayOf<Child.State>`.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  /// - Returns: A `ComposedReducerChild` representing a `Reducer`
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// @Composer
  /// struct Child {
  ///   struct State: Identifiable {
  ///     var id: UUID
  ///   }
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .identifiedArray("child", of: Child.self)
  ///   ]
  /// )
  /// @Composer
  /// struct Parent {
  /// }
  /// ```
  /// Generates the following output:
  ///
  public static func identifiedArray<Child: Reducer>(
    _ name: String,
    of: Child.Type
  ) -> Self where Child.State: Identifiable { Self() }

  /// Constructs a `ComposedReducerChild` representing an array of child reducer state, respresented by an `IdentifiedArrayOf<Child.State>`.
  /// - Parameters:
  ///   - name: The name of the child. The name will be used to generate corresponding members of `State` and `Action`.
  ///   - of: The type of `Reducer` to be used.
  ///   - initialState: An initial value to assign to generated memeber of `State`
  /// - Returns: A `ComposedReducerChild` representing a `Reducer`
  ///
  /// Given the following input example:
  ///
  /// ```swift
  /// @Composer
  /// struct Child {
  ///   struct State: Identifiable {
  ///     var id: UUID
  ///   }
  /// }
  ///
  /// @ComposeReducer(
  ///   children: [
  ///     .identifiedArray("child", of: Child.self, initialState: .init())
  ///   ]
  /// )
  /// @Composer
  /// struct Parent {
  /// }
  /// ```
  ///
  /// Generates the following output:
  ///
  public static func identifiedArray<Child: Reducer>(
    _ name: String,
    of: Child.Type,
    initialState: @autoclosure () -> IdentifiedArrayOf<Child.State>
  ) -> Self where Child.State: Identifiable { Self() }

  
  public static func presentsReducer<Child: Reducer>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func presentsAlert(
    _ name: String = "alert"
  ) -> Self { Self() }

  public static func presentsAlert<Action>(
    _ name: String = "alert",
    of: Action.Type
  ) -> Self { Self() }

  public static func presentsConfirmationDialog(
    _ name: String = "confirmationDialog"
  ) -> Self { Self() }

  public static func presentsConfirmationDialog<Action>(
    _ name: String = "confirmationDialog",
    of: Action.Type
  ) -> Self { Self() }

  public static func presentsDestination(
    _ name: String = "destination",
    reducerName: String = "Destination",
    children: [ComposedEnumReducerChild]
  ) -> Self { Self() }

  public static func navigationStack(
    _ name: String = "path",
    reducerName: String = "Path",
    children: [ComposedNavigationStackChild]
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type,
    initialValue: @autoclosure () -> Child
  ) -> Self { Self() }

}

public struct ComposedEnumReducerChild {
  fileprivate init() {}
}

extension ComposedEnumReducerChild {

  public static func alert(
    _ name: String = "alert"
  ) -> Self { Self() }

  public static func alert<Action>(
    _ name: String = "alert",
    of: Action.Type
  ) -> Self { Self() }

  public static func confirmationDialog(
    _ name: String = "confirmationDialog"
  ) -> Self { Self() }

  public static func confirmationDialog<Action>(
    _ name: String = "confirmationDialog",
    of: Action.Type
  ) -> Self { Self() }

  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type,
    initialState: @autoclosure () -> Child.State
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type,
    initialValue: @autoclosure () -> Child
  ) -> Self { Self() }

  public static func stateless(
    _ name: String
  ) -> Self { Self() }
}

public struct ComposedNavigationStackChild {
  fileprivate init() {}
}

extension ComposedNavigationStackChild {

  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func reducer<Child: Reducer>(
    _ name: String,
    of: Child.Type,
    initialState: @autoclosure () -> Child.State
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type
  ) -> Self { Self() }

  public static func state<Child>(
    _ name: String,
    of: Child.Type,
    initialValue: @autoclosure () -> Child
  ) -> Self { Self() }

  public static func stateless(
    _ name: String
  ) -> Self { Self() }
}

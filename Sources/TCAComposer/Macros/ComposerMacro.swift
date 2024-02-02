import ComposableArchitecture

/// Automatically generates members of a `Reducer` as directed via various `@Compose...` macros.
///
/// The following macros are used by ``Composer()`` to build a complete `Reducer` implementation
/// * Defining children of a `Reducer`
///    * ``ComposeReducer(_:children:)`` - Specify the composed children of a `Reducer`.
///    * ``ComposeEnumReducer(_:children:)`` - Specify the composed children of `Reducer` with enumerated `State`.
/// * Defining `body` of a `Reducer`
///   * ``ComposeBody(position:)`` - Attached to a reducer function declartion to include in the composed `body`.
///   * ``ComposeBodyActionCase(_:)`` - Adds a new `case` to `Action` and also includes the reduce funciton in the `body`.
/// * Defining the `Action` of ` Reducer`
///   * ``ComposeActionCase(_:)`` - Adds a new case to `Action`
/// * Defninging custom `ScopePath`
///   * ``ComposeScopePath(action:)``
/// * Action support
///   * ``ComposeAllCasePaths()`` -  Attached to an `AllCasePaths` declaration inside of `Action`.  Needed to support dynamically adding `CasePath`s to an existing `Action` declartion.
///
@attached(extension, conformances: ComposableArchitecture.Reducer)
@attached(
  member,
  names:
    named(State),
  named(Action),
  named(init),
  named(body),
  named(AllComposedScopeCases),
  named(AllComposedScopePaths),
  named(Destination),
  named(Path),
  arbitrary)
@attached(memberAttribute)
public macro Composer() =
  #externalMacro(module: "TCAComposerMacros", type: "ComposerMacro")

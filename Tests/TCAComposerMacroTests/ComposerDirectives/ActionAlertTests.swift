import MacroTesting
import XCTest

import TCAComposerMacros

final class ActionAlertTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeActionAlertCaseMacro.self,
               _ComposerCasePathableActions.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testAlertActionDefaultName() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsAlert()
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionAlertCase
          enum AlertAction {
              case confirmDelete
          }
      }
      """
    } expansion: {
      #"""
      struct Feature {
          @CasePathable
          enum AlertAction {
              case confirmDelete
          }

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var alert: AlertState<AlertAction>?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case alert(PresentationAction<AlertAction>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .ifLet(\.$alert, action: \Action.Cases.alert)
          }

          struct AllComposedScopePaths {
              var alert: TCAComposer.ScopePath<Feature.State, AlertState<AlertAction>?, Feature.Action, PresentationAction<AlertAction>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.alert, action: \Action.Cases.alert)
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testNamedAlertAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsAlert("deleteAlert")
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionAlertCase
          enum AlertAction {
              case confirmDelete
          }
      }
      """
    } expansion: {
      #"""
      struct Feature {
          @CasePathable
          enum AlertAction {
              case confirmDelete
          }

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var deleteAlert: AlertState<AlertAction>?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case deleteAlert(PresentationAction<AlertAction>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .ifLet(\.$deleteAlert, action: \Action.Cases.deleteAlert)
          }

          struct AllComposedScopePaths {
              var deleteAlert: TCAComposer.ScopePath<Feature.State, AlertState<AlertAction>?, Feature.Action, PresentationAction<AlertAction>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.deleteAlert, action: \Action.Cases.deleteAlert)
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testNestedNamedAlertAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsAlert("deleteAlert")
          ]
      )
      @Composer
      struct Feature {
          enum Actions {
              @ComposeActionAlertCase
              enum Alert {
                  case confirmDelete
              }
          }
      }
      """
    } expansion: {
      #"""
      struct Feature {
          enum Actions {
              @CasePathable
              enum Alert {
                  case confirmDelete
              }
          }

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var deleteAlert: AlertState<Actions.Alert>?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case deleteAlert(PresentationAction<Actions.Alert>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .ifLet(\.$deleteAlert, action: \Action.Cases.deleteAlert)
          }

          struct AllComposedScopePaths {
              var deleteAlert: TCAComposer.ScopePath<Feature.State, AlertState<Actions.Alert>?, Feature.Action, PresentationAction<Actions.Alert>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.deleteAlert, action: \Action.Cases.deleteAlert)
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testDestinationAlertAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsDestination(
                  children: [
                      .alert()
                  ]
              )
          ]
      )
      @Composer
      struct Feature {
          enum Actions {
              @ComposeActionAlertCase
              enum Alert {
                  case confirmDelete
              }
          }
      }
      """
    } expansion: {
      #"""
      struct Feature {
          enum Actions {
              @CasePathable
              enum Alert {
                  case confirmDelete
              }
          }

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var destination: Destination.State?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case destination(PresentationAction<Destination.Action>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .ifLet(\.$destination, action: \Action.Cases.destination) {
                  Destination()
              }
          }

          struct AllComposedScopePaths {
              var destination: Destination.AllComposedScopePaths {
                  get {
                      return Destination.AllComposedScopePaths()
                  }
              }
          }

          struct Destination: ComposableArchitecture.Reducer {
              @CasePathable
              @ObservableState
              @dynamicMemberLookup
              enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable {
                  case alert(AlertState<Actions.Alert>)
              }
              @CasePathable
              enum Action: CasePaths.CasePathable {
                  case alert(Actions.Alert)
              }
              @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
              var body: some ReducerOf<Self> {
                  ComposableArchitecture.EmptyReducer()
              }
              struct AllComposedScopePaths {
                  var alert: TCAComposer.ScopePath<Feature.State, AlertState<Actions.Alert>?, Feature.Action, PresentationAction<Actions.Alert>> {
                      get {
                          return TCAComposer.ScopePath(state: \Feature.State.destination?.alert, action: \Feature.Action.Cases.destination.alert)
                      }
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testAlertActionWrongName() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsAlert()
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionAlertCase("deleteAlert")
          enum AlertAction {
              case confirmDelete
          }
      }
      """
    } diagnostics: {
      """
      @ComposeReducer(
          children: [
              .presentsAlert()
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionAlertCase("deleteAlert")
          ┬─────────────────────────────────────
          ╰─ 🛑 Could not find a match for "deleteAlert", macro will be ignored.
          enum AlertAction {
              case confirmDelete
          }
      }
      """
    }
  }
  
  func testAlertActionWrongType() {
    assertMacro {
      """
      struct Feature {
          @ComposeActionAlertCase
          func handleAlert(state: inout State, action: AlertAction) -> EffectOf<Self> {
              return .none
          }
      }
      """
    } diagnostics: {
      """
      struct Feature {
          @ComposeActionAlertCase
          ┬──────────────────────
          ╰─ 🛑 @ComposeActionAlertCase cannot be applied to a function declaration.
          func handleAlert(state: inout State, action: AlertAction) -> EffectOf<Self> {
              return .none
          }
      }
      """
    }
  }
}

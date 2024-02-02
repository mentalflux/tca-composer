import MacroTesting
import XCTest

import TCAComposerMacros

final class BodyActionAlertTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeBodyActionAlertCaseMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testAlertAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsAlert()
          ]
      )
      @Composer
      struct Feature {
          enum AlertAction {
              case confirmDelete
          }
      
          @ComposeBodyActionAlertCase
          func handleAlert(state: inout State, action: AlertAction) -> EffectOf<Self> {
              return .none
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
          func handleAlert(state: inout State, action: AlertAction) -> EffectOf<Self> {
              return .none
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
              ComposableArchitecture.CombineReducers {
                  TCAComposer.ReduceAction(\Action.Cases.alert.presented) { state, action in
                      return self.handleAlert(state: &state, action: action)
                  }
              }
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
  
}

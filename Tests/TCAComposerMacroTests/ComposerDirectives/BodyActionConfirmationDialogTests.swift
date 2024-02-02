import MacroTesting
import XCTest

import TCAComposerMacros

final class BodyActionConfirmationDialogTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeBodyActionConfirmationDialogCaseMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testConfirmationDialogAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsConfirmationDialog()
          ]
      )
      @Composer
      struct Feature {
          enum ConfirmationDialogAction {
              case confirmDelete
          }
      
          @ComposeBodyActionConfirmationDialogCase
          func handleConfirmationDialog(state: inout State, action: ConfirmationDialogAction) -> EffectOf<Self> {
              return .none
          }
      }
      """
    } expansion: {
      #"""
      struct Feature {
          @CasePathable
          enum ConfirmationDialogAction {
              case confirmDelete
          }
          func handleConfirmationDialog(state: inout State, action: ConfirmationDialogAction) -> EffectOf<Self> {
              return .none
          }

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var confirmationDialog: ConfirmationDialogState<ConfirmationDialogAction>?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case confirmationDialog(PresentationAction<ConfirmationDialogAction>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.CombineReducers {
                  TCAComposer.ReduceAction(\Action.Cases.confirmationDialog.presented) { state, action in
                      return self.handleConfirmationDialog(state: &state, action: action)
                  }
              }
              .ifLet(\.$confirmationDialog, action: \Action.Cases.confirmationDialog)
          }

          struct AllComposedScopePaths {
              var confirmationDialog: TCAComposer.ScopePath<Feature.State, ConfirmationDialogState<ConfirmationDialogAction>?, Feature.Action, PresentationAction<ConfirmationDialogAction>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.confirmationDialog, action: \Action.Cases.confirmationDialog)
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

import MacroTesting
import XCTest

import TCAComposerMacros

final class ActionConfirmationDialogTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeActionConfirmationDialogCaseMacro.self,
               _ComposerCasePathableActions.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testConfirmationDialogActionDefaultName() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsConfirmationDialog()
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionConfirmationDialogCase
          enum ConfirmationDialogAction {
              case confirmDelete
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
              ComposableArchitecture.EmptyReducer()
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
  
  func testNamedConfirmationDialogAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsConfirmationDialog("deleteConfirmationDialog")
          ]
      )
      @Composer
      struct Feature {
          @ComposeActionConfirmationDialogCase
          enum ConfirmationDialogAction {
              case confirmDelete
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

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              @Presents var deleteConfirmationDialog: ConfirmationDialogState<ConfirmationDialogAction>?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case deleteConfirmationDialog(PresentationAction<ConfirmationDialogAction>)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .ifLet(\.$deleteConfirmationDialog, action: \Action.Cases.deleteConfirmationDialog)
          }

          struct AllComposedScopePaths {
              var deleteConfirmationDialog: TCAComposer.ScopePath<Feature.State, ConfirmationDialogState<ConfirmationDialogAction>?, Feature.Action, PresentationAction<ConfirmationDialogAction>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.deleteConfirmationDialog, action: \Action.Cases.deleteConfirmationDialog)
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testDestinationConfirmationDialogAction() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .presentsDestination(
                  children: [
                      .confirmationDialog()
                  ]
              )
          ]
      )
      @Composer
      struct Feature {
          enum Actions {
              @ComposeActionConfirmationDialogCase
              enum ConfirmationDialog {
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
              enum ConfirmationDialog {
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
                  case confirmationDialog(ConfirmationDialogState<Actions.ConfirmationDialog>)
              }
              @CasePathable
              enum Action: CasePaths.CasePathable {
                  case confirmationDialog(Actions.ConfirmationDialog)
              }
              @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
              var body: some ReducerOf<Self> {
                  ComposableArchitecture.EmptyReducer()
              }
              struct AllComposedScopePaths {
                  var confirmationDialog: TCAComposer.ScopePath<Feature.State, ConfirmationDialogState<Actions.ConfirmationDialog>?, Feature.Action, PresentationAction<Actions.ConfirmationDialog>> {
                      get {
                          return TCAComposer.ScopePath(state: \Feature.State.destination?.confirmationDialog, action: \Feature.Action.Cases.destination.confirmationDialog)
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
}

import MacroTesting
import XCTest
import TCAComposerMacros

final class ComposePresentationMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testAlertDefaultAction() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .presentsAlert()
        ]
      )
      @Composer
      struct Feature {
      }
      """
    } expansion: {
      #"""
      struct Feature {

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          @Presents var alert: AlertState<Never>?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case alert(PresentationAction<Never>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$alert, action: \Action.Cases.alert)
        }

        struct AllComposedScopePaths {
          var alert: TCAComposer.ScopePath<Feature.State, AlertState<Never>?, Feature.Action, PresentationAction<Never>> {
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
  
  func testAlertActionOf() {
    assertMacro {
      """
      enum AlertAction {
      }
      
      @ComposeReducer(
        children: [
          .presentsAlert("alert", of: AlertAction.self)
        ]
      )
      @Composer
      struct Feature {
      }
      """
    } expansion: {
      #"""
      enum AlertAction {
      }
      struct Feature {

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
  
  func testConfirmationDialogDefaultAction() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .presentsConfirmationDialog()
        ]
      )
      @Composer
      struct Feature {
      }
      """
    } expansion: {
      #"""
      struct Feature {

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          @Presents var confirmationDialog: ConfirmationDialogState<Never>?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case confirmationDialog(PresentationAction<Never>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$confirmationDialog, action: \Action.Cases.confirmationDialog)
        }

        struct AllComposedScopePaths {
          var confirmationDialog: TCAComposer.ScopePath<Feature.State, ConfirmationDialogState<Never>?, Feature.Action, PresentationAction<Never>> {
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
  
  func testPresentsChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .presentsReducer("child", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        enum AlertAction {
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum AlertAction {
        }

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          @Presents var child: Counter.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case child(PresentationAction<Counter.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$child, action: \Action.Cases.child) {
            Counter()
          }
        }

        struct AllComposedScopePaths {
          var child: TCAComposer.ScopePath<Feature.State, Counter.State?, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.child, action: \Action.Cases.child.presented)
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

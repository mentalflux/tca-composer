
import MacroTesting
import XCTest

import TCAComposerMacros


final class ActionCaseTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeActionCaseMacro.self,
               _ComposerCasePathableActions.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testDelegateAction() {
    assertMacro {
      """
      @Composer
      struct Feature {
          @ComposeActionCase
          enum DelegateAction {
              case notify
          }
      }
      """
    } expansion: {
      """
      struct Feature {
          @CasePathable
          enum DelegateAction {
              case notify
          }

          @ObservableState
          struct State: Equatable {

          }

          @CasePathable
          enum Action {
              case delegate(DelegateAction)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testDelegate() {
    assertMacro {
      """
      @Composer
      struct Feature {
          @ComposeActionCase
          enum Delegate {
              case notify
          }
      }
      """
    } expansion: {
      """
      struct Feature {
          enum Delegate {
              case notify
          }

          @ObservableState
          struct State: Equatable {

          }

          @CasePathable
          enum Action {
              case delegate(Delegate)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testDelegateCustomName() {
    assertMacro {
      """
      @Composer
      struct Feature {
          @ComposeActionCase("parent")
          enum Delegate {
              case notify
          }
      }
      """
    } expansion: {
      """
      struct Feature {
          enum Delegate {
              case notify
          }

          @ObservableState
          struct State: Equatable {

          }

          @CasePathable
          enum Action {
              case parent(Delegate)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testDelegateActionsScoped() {
    assertMacro {
      """
      @Composer
      struct Feature {
          enum Actions {
              @ComposeActionCase
              enum DelegateAction {
                  case notify
              }
          }
      }
      """
    } expansion: {
      """
      struct Feature {
          enum Actions {
              @CasePathable
              enum DelegateAction {
                  case notify
              }
          }

          @ObservableState
          struct State: Equatable {

          }

          @CasePathable
          enum Action {
              case delegate(Actions.DelegateAction)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  // Need to ponder this further...
//  func testDelegateActionScoped() {
//    assertMacro {
//      """
//      @Composer
//      struct Feature {
//          enum Action {
//              @ComposeActionCase
//              enum DelegateAction {
//                  case notify
//              }
//      
//              @ComposeAllCasePaths
//              struct AllCasePaths {}
//          }
//      }
//      """
//    } expansion: {
//      """
//      struct Feature {
//          @_ComposerCasePathable @_ComposedActionMember("delegate", of: Action.DelegateAction.self)
//          enum Action {
//              enum DelegateAction {
//                  case notify
//              }
//
//              @ComposeAllCasePaths
//              struct AllCasePaths {}
//          }
//
//          @ObservableState
//          struct State: Equatable {
//
//          }
//
//          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
//          var body: some ReducerOf<Self> {
//              ComposableArchitecture.EmptyReducer()
//          }
//      }
//
//      extension Feature: ComposableArchitecture.Reducer {
//      }
//      """
//    }
//  }
  
  func testAlertActionWrongType() {
    assertMacro {
      """
      struct Feature {
          @ComposeActionCase
          func view(state: inout State, action: Action) -> EffectOf<Self> {
              return .none
          }
      }
      """
    } diagnostics: {
      """
      struct Feature {
          @ComposeActionCase
          ┬─────────────────
          ╰─ 🛑 @ComposeActionCase cannot be applied to a function declaration.
          func view(state: inout State, action: Action) -> EffectOf<Self> {
              return .none
          }
      }
      """
    }
  }
  
  func testAlertActionSameNameAsChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
          @ComposeActionCase
          enum CounterAction {}
      }
      """
    } diagnostics: {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
          @ComposeActionCase
          ┬─────────────────
          ╰─ 🛑 Duplicate definition of an action named 'counter'.
          enum CounterAction {}
      }
      """
    }
  }
}

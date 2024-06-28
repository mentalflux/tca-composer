import MacroTesting
import XCTest

import TCAComposerMacros

final class BodyActionCaseTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeBodyActionCaseMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testViewAction() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase
        func view(state: inout State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum ViewAction {
          case buttonClicked
        }
        func view(state: inout State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action: ComposableArchitecture.ViewAction {
          case view(ViewAction)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
              return self.view(state: &state, action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
//  func testViewActionScopedExistingAction() {
//    assertMacro {
//      """
//      @Composer
//      struct Feature {
//      
//          enum Action {
//              enum View {
//                  case buttonClicked
//              }
//      
//              @ComposeAllCasePaths
//              struct AllCasePaths {}
//          }
//      
//          @ComposeBodyActionCase
//          func view(state: inout State, action: Action.View) -> EffectOf<Self> {
//              return .none
//          }
//      }
//      """
//    } expansion: {
//      #"""
//      struct Feature {
//          @_ComposedAction(.viewAction) @_ComposerCasePathable @_ComposedActionMember("view", of: Action.View.self)
//
//          enum Action {
//              enum View {
//                  case buttonClicked
//              }
//
//              @ComposeAllCasePaths
//              struct AllCasePaths {}
//          }
//          func view(state: inout State, action: Action.View) -> EffectOf<Self> {
//              return .none
//          }
//
//          @ObservableState
//          struct State: Equatable {
//
//          }
//
//          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
//          var body: some ReducerOf<Self> {
//              ComposableArchitecture.CombineReducers {
//                  TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
//                      return self.view(state: &state, action: action)
//                  }
//              }
//          }
//      }
//
//      extension Feature: ComposableArchitecture.Reducer {
//      }
//      """#
//    }
//  }
  
  func testViewActionCustomName() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase("view")
        func reduceView(state: inout State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum ViewAction {
          case buttonClicked
        }
        func reduceView(state: inout State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action: ComposableArchitecture.ViewAction {
          case view(ViewAction)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
              return self.reduceView(state: &state, action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testViewActionMissingAction() {
    assertMacro {
      """
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase
        func view(state: inout State) -> EffectOf<Self> {
          return .none
        }
      }
      """
    } diagnostics: {
      """
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }

        @ComposeBodyActionCase
        ┬─────────────────────
        ╰─ 🛑 @ComposeBodyActionCase requires an action parameter to infer an Action type.
        func view(state: inout State) -> EffectOf<Self> {
          return .none
        }
      }
      """
    }
  }
  
  func testViewActionNoReturn() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase
        func view(state: inout State, action: Action) {
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum ViewAction {
          case buttonClicked
        }
        func view(state: inout State, action: Action) {
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action: ComposableArchitecture.ViewAction {
          case view(Action)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
              self.view(state: &state, action: action)
              return .none
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testViewActionNoState() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase
        func view(action: ViewAction) -> EffectOf<Self> {
          return .none
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum ViewAction {
          case buttonClicked
        }
        func view(action: ViewAction) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action: ComposableArchitecture.ViewAction {
          case view(ViewAction)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
              return self.view(action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testViewActionImmutableState() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Feature {
        enum ViewAction {
          case buttonClicked
        }
      
        @ComposeBodyActionCase
        func view(state: State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum ViewAction {
          case buttonClicked
        }
        func view(state: State, action: ViewAction) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action: ComposableArchitecture.ViewAction {
          case view(ViewAction)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
              return self.view(state: state, action: action)
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

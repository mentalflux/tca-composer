#if canImport(TCAComposerMacros)
import MacroTesting
import XCTest

import TCAComposerMacros

final class ReducerExistingStateTests: XCTestCase {
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
  
  func testNoChildren() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Counter {
        struct State: Equatable {
          var count = 0
        }
      }
      """
    } expansion: {
      """
      struct Counter {
        @ObservableState
        struct State: Equatable {
          var count = 0
        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
        }
      }

      extension Counter: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testSingleChild() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .reducer("counter", of: Counter.self)
          ]
      )
      @Composer
      struct Feature {
        struct State: Equatable {
          var count = 0
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counter", of: Counter.State.self) @ObservableState
        struct State: Equatable {
          var count = 0
        }

          @CasePathable
          enum Action {
              case counter(Counter.Action)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
                  Counter()
              }
          }

          struct AllComposedScopePaths {
              var counter: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
                  get {
                      return TCAComposer.ScopePath(state: \State.counter, action: \Action.Cases.counter)
                  }
              }
          }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  // TODO: Move this to @ComposeEnumReducer
  func testSingleChildEnumState() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .reducer("counter", of: Counter.self)
          ]
      )
      @Composer
      struct Feature {
        enum State: Equatable {
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerCasePathable
        enum State: Equatable {
        }

          @CasePathable
          enum Action {
              case counter(Counter.Action)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
                  Counter()
              }
          }

          struct AllComposedScopePaths {
              var counter: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
                  get {
                      return TCAComposer.ScopePath(state: \State.counter, action: \Action.Cases.counter)
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
#endif

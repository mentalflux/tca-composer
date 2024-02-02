import MacroTesting
import XCTest

import TCAComposerMacros

final class BodyOnChangeTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeBodyOnChangeMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  // TODO: Need more variations of signature parameter combinations, and error paths.
  func testOnChangeOfChild() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBodyOnChange(of: \State.counter)
        func counter(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        func counter(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var counter: Counter.State

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
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
          ComposableArchitecture.EmptyReducer()
          .onChange(of: \.counter) { oldValue, newValue in
            ComposableArchitecture.Reduce { state, action in
              return self.counter(oldValue: oldValue, newValue: newValue, state: &state, action: action)
            }
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
  
  func testOnChangeOfChildBadKeyPath() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBodyOnChange(of: \Counter.State.count)
        func counter(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } diagnostics: {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBodyOnChange(of: \Counter.State.count)
                                 ┬───────────────────
                                 ╰─ 🛑 Keypath must begin with "\State."
        func counter(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    }
  }
}

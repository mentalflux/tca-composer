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
  
  func testOnChangeOfBindable() {
    assertMacro {
      #"""
      @ComposeReducer(
        .bindable
      )
      @Composer
      struct Feature {
        struct State {
          var text: String
        }
      
        @ComposeBodyOnChange(of: \State.text, attachment: .binding)
        func handleBindingChange(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        @ObservableState
        struct State {
          var text: String
        }
        func handleBindingChange(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }

        @CasePathable
        enum Action: ComposableArchitecture.BindableAction {
          case binding(BindingAction<State>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.BindingReducer()
          .onChange(of: \.text) { oldValue, newValue in
            ComposableArchitecture.Reduce { state, action in
              return self.handleBindingChange(oldValue: oldValue, newValue: newValue, state: &state, action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  // TODO: Fix this test so that the diagnostic is only produce once. analyze() is called
  // for both composeAttributesForState() and composeMembers(). Need to take a deeper look at
  // disabling diagnostic emission under these cirumstances.
  func testOnChangeOfBindableButNotBindable() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        struct State {
          var text: String
        }
      
        @ComposeBodyOnChange(of: \State.text, attachment: .binding)
        func handleBindingChange(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } diagnostics: {
      #"""
      @Composer
      struct Feature {
        struct State {
          var text: String
        }

        @ComposeBodyOnChange(of: \State.text, attachment: .binding)
                                                          ┬───────
                                                          ├─ 🛑 `.binding` attachment requires the Reducer have the `.bindable` option specified.
                                                          ╰─ 🛑 `.binding` attachment requires the Reducer have the `.bindable` option specified.
        func handleBindingChange(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    }
  }
  
  func testOnChangeOfChildScope() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBodyOnChange(of: \State.counter, attachment: .scope("counter"))
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
  
  func testOnChangeOfChildScopeInvalidName() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBodyOnChange(of: \State.counter, attachment: .scope("counter1"))
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
        @ComposeBodyOnChange(of: \State.counter, attachment: .scope("counter1"))
                                                             ┬─────────────────
                                                             ╰─ 🛑 'counter1' is not a valid scoped child reducer name.
        func counter(oldValue: Counter.State, newValue: Counter.State, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } 
  }
}

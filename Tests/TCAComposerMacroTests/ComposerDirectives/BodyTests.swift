
import MacroTesting
import XCTest

import TCAComposerMacros

final class BodyTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeBodyMacro.self,
               ComposeActionCaseMacro.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testNoActionCasePath() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll(state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduceAll(state: &state, action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testNoActionCasePathInvalidNamedParameter() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: inout State, action: Action, foo: Int) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } diagnostics: {
      """
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: inout State, action: Action, foo: Int) -> EffectOf<Self> {
                                                           ┬──
                                                           ╰─ 🛑 @ComposeBody doesn't allow a parameter named "foo" in the function signature.
          return .none
        }
      }
      """
    }
  }
  
  func testNoActionCasePathInvalidUnamedParameter() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(_ unnamed: Int, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } diagnostics: {
      """
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(_ unnamed: Int, state: inout State, action: Action) -> EffectOf<Self> {
                       ┬
                       ╰─ 🛑 @ComposeBody doesn't allow a parameter named "_" in the function signature.
          return .none
        }
      }
      """
    }
  }
  
  func testNoActionCasePathIdNotAllowed() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(id: UUID, state: inout State, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } diagnostics: {
      """
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(id: UUID, state: inout State, action: Action) -> EffectOf<Self> {
                       ┬─
                       ╰─ 🛑 @ComposeBody doesn't allow a parameter named "id" unless using identifiedAction.
          return .none
        }
      }
      """
    }
  }
  
  func testNoActionCasePathNoReturn() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: inout State, action: Action) {
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll(state: inout State, action: Action) {
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              self.reduceAll(state: &state, action: action)
              return .none
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testNoActionCasePathImmutableState() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: state, action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll(state: state, action: Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduceAll(state: state, action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testNoActionCasePathNoState() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(action: Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll(action: Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduceAll(action: action)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testNoActionCasePathNoAction() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll(state: inout state) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll(state: inout state) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduceAll(state: &state)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testNoActionCasePathNoParameters() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeBody
        func reduceAll() -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      """
      struct Feature {
        func reduceAll() -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduceAll()
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testChildAction() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self, initialValue: .init())
        ]
      )
      @Composer
      struct Feature {
        @ComposeBody(action: \Action.Cases.counter)
        func handleCounter(state: inout State, action: Counter.Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        func handleCounter(state: inout State, action: Counter.Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var counter: Counter.State = .init()

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
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.counter) { state, action in
              return self.handleCounter(state: &state, action: action)
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
  
  func testChildDestructureResultAction() {
    assertMacro {
      #"""
      @Composer
      struct Feature {
        @ComposeActionCase
        enum EffectAction {
          case result(Result<Int, Error>)
        }
        @ComposeBody(action: \Action.Cases.effect.result.success)
        func resultSuccess(state: inout State, action: Int) {
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        @CasePathable
        enum EffectAction {
          case result(Result<Int, Error>)
        }
        func resultSuccess(state: inout State, action: Int) {
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {
          case effect(EffectAction)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceAction(\Action.Cases.effect.result.success) { state, action in
              self.resultSuccess(state: &state, action: action)
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
  
  func testDestructureIdentifiedAction() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .identifiedArray("rows", of: Row.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBody(identifiedAction: \Action.Cases.rows, elementAction: \Row.Action.Cases.delegate.notify)
        func handleRowNotify(state: inout State, id: Row.ID, action: Result<Int, Error>) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        func handleRowNotify(state: inout State, id: Row.ID, action: Result<Int, Error>) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var rows: IdentifiedArrayOf<Row.State>

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case rows(IdentifiedActionOf<Row>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            TCAComposer.ReduceIdentifiedAction(\Action.Cases.rows, element: \Row.Action.Cases.delegate.notify) { state, id, action in
              return self.handleRowNotify(state: &state, id: id, action: action)
            }
          }
          .forEach(\.rows, action: \Action.Cases.rows) {
            Row()
          }
        }

        struct AllComposedScopePaths {
          var rows: TCAComposer.ScopePath<Feature.State, IdentifiedArrayOf<Row.State>, Feature.Action, IdentifiedActionOf<Row>> {
            get {
              return TCAComposer.ScopePath(state: \State.rows, action: \Action.Cases.rows)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testChildActionAfterCore() {
    assertMacro {
      #"""
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self),
          .reducer("optionalCounter", of: Counter?.self)
        ]
      )
      @Composer
      struct Feature {
        @ComposeBody(action: \Action.Cases.counter, position: .afterCore)
        func counter(state: inout State, action: Counter.Action) -> EffectOf<Self> {
          return .none
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        func counter(state: inout State, action: Counter.Action) -> EffectOf<Self> {
          return .none
        }

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var counter: Counter.State
          var optionalCounter: Counter.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case counter(Counter.Action)
          case optionalCounter(Counter.Action)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
            Counter()
          }
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.optionalCounter, action: \Action.Cases.optionalCounter) {
            Counter()
          }
          TCAComposer.ReduceAction(\Action.Cases.counter) { state, action in
            return self.counter(state: &state, action: action)
          }
        }

        struct AllComposedScopePaths {
          var counter: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.counter, action: \Action.Cases.counter)
            }
          }
          var optionalCounter: TCAComposer.ScopePath<Feature.State, Counter.State?, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.optionalCounter, action: \Action.Cases.optionalCounter)
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

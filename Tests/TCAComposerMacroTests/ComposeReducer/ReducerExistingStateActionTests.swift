import MacroTesting
import XCTest

import TCAComposerMacros

final class ReducerExistingStateActionTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               _ComposerCasePathableMacro.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testEmpty() {
    assertMacro {
      """
      @Composer
      struct Empty {
        struct State {
        }
      
        enum Action {
        }
      }
      """
    } expansion: {
      """
      struct Empty {
        @ObservableState
        struct State {
        }

        enum Action {

          struct AllCasePaths {

          }

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testEmptyCasePathable() {
    assertMacro {
      """
      @Composer
      struct Empty {
        @ObservableState
        struct State {
        }
        @CasePathable
        enum Action {
        }
      }
      """
    } diagnostics: {
      """
      @Composer
      struct Empty {
        @ObservableState
        struct State {
        }
        @CasePathable
        ┬────────────
        ╰─ 🛑 @Composer automatically provides CasePathable conformance for `Action` and is not compatible with `@CasePathable`.
           ✏️ Remove `@CasePathable`.
        enum Action {
        }
      }
      """
    } fixes: {
      """
      @Composer
      struct Empty {
        @ObservableState
        struct State {
        }
      }
      """
    } expansion: {
      """
      struct Empty {
        @ObservableState
        struct State {
        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testChildNoComposeCasePaths() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Empty {
        @ObservableState
        struct State {
        }
        enum Action {
        }
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
      struct Empty {
        @ObservableState
        struct State {
        }
        enum Action {
        ╰─ 🛑 'Action` must contain an empty `AllCasePaths` struct declaration to support dymamically generated case members.
           ✏️ Add `AllCasePaths`.
        }
      }
      """
    }fixes: {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Empty {
        @ObservableState
        struct State {
        }
        enum Action {
      @ComposeAllCasePaths
      struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Empty {
        @ObservableState
        @_ComposerScopePathable @_ComposedStateMember("counter", of: Counter.State.self)
        struct State {
        }@_ComposedActionMember("counter", of: Counter.Action.self)
        enum Action {
      @ComposeAllCasePaths
      struct AllCasePaths {}

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
            Counter()
          }
        }

        struct AllComposedScopePaths {
          var counter: TCAComposer.ScopePath<Empty.State, Counter.State, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.counter, action: \Action.Cases.counter)
            }
          }
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testPublicChildNoComposeCasePaths() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      public struct Empty {
        @ObservableState
        public struct State {
        }
        public enum Action {
        }
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
      public struct Empty {
        @ObservableState
        public struct State {
        }
        public enum Action {
        ╰─ 🛑 'Action` must contain an empty `AllCasePaths` struct declaration to support dymamically generated case members.
           ✏️ Add `AllCasePaths`.
        }
      }
      """
    } fixes: {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      public struct Empty {
        @ObservableState
        public struct State {
        }
        public enum Action {
      @ComposeAllCasePaths
      public struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      public struct Empty {
        @ObservableState
        @_ComposerScopePathable @_ComposedStateMember("counter", of: Counter.State.self)
        public struct State {
        }@_ComposedActionMember("counter", of: Counter.Action.self)
        public enum Action {
      @ComposeAllCasePaths
      public struct AllCasePaths {}

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        public var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
            Counter()
          }
        }

        public struct AllComposedScopePaths {
          public var counter: TCAComposer.ScopePath<Empty.State, Counter.State, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.counter, action: \Action.Cases.counter)
            }
          }
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
   
  func testBindable() {
    assertMacro {
      """
      @ComposeReducer(.bindable)
      @Composer
      struct Feature {
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      """
      struct Feature {
        @ObservableState
        struct State {
        }
        @_ComposedAction(.bindableAction) @_ComposedActionMember("binding", of: BindingAction<State>.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.BindingReducer()
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
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
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counter", of: Counter.State.self) @ObservableState
        struct State {
        }@_ComposedActionMember("counter", of: Counter.Action.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
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

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testMultipleChildren() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .reducer("counter1", of: Counter.self),
              .reducer("counter2", of: Counter.self)
          ]
      )
      @Composer
      struct Feature {
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counter1", of: Counter.State.self) @_ComposedStateMember("counter2", of: Counter.State.self) @ObservableState
        struct State {
        }@_ComposedActionMember("counter1", of: Counter.Action.self) @_ComposedActionMember("counter2", of: Counter.Action.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

            static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.Scope(state: \.counter1, action: \Action.Cases.counter1) {
                  Counter()
              }
              ComposableArchitecture.Scope(state: \.counter2, action: \Action.Cases.counter2) {
                  Counter()
              }
          }

          struct AllComposedScopePaths {
              var counter1: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
                  get {
                      return TCAComposer.ScopePath(state: \State.counter1, action: \Action.Cases.counter1)
                  }
              }
              var counter2: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
                  get {
                      return TCAComposer.ScopePath(state: \State.counter2, action: \Action.Cases.counter2)
                  }
              }
          }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testOptionalChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("optionalCounter", of: Counter?.self),
        ]
      )
      @Composer
      struct Feature {
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("optionalCounter", of: Counter.State?.self) @ObservableState
        struct State {
        }@_ComposedActionMember("optionalCounter", of: Counter.Action.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.optionalCounter, action: \Action.Cases.optionalCounter) {
            Counter()
          }
        }

        struct AllComposedScopePaths {
          var optionalCounter: TCAComposer.ScopePath<Feature.State, Counter.State?, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.optionalCounter, action: \Action.Cases.optionalCounter)
            }
          }
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testArrayOfChild() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .identifiedArray("counters", of: Counter.self),
          ]
      )
      @Composer
      struct Feature {
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counters", of: IdentifiedArrayOf<Counter.State>.self) @ObservableState
        struct State {
        }@_ComposedActionMember("counters", of: IdentifiedActionOf<Counter>.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

            static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
              .forEach(\.counters, action: \Action.Cases.counters) {
                  Counter()
              }
          }

          struct AllComposedScopePaths {
              var counters: TCAComposer.ScopePath<Feature.State, IdentifiedArrayOf<Counter.State>, Feature.Action, IdentifiedActionOf<Counter>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.counters, action: \Action.Cases.counters)
                  }
              }
          }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testComplex() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("counter1", of: Counter.self),
          .reducer("counter2", of: Counter.self),
          .identifiedArray("counters", of: Counter.self),
          .reducer("optionalCounter", of: Counter?.self)
        ]
      )
      @Composer
      struct Feature {
        struct State {
        }
      
        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}
        }
      }
      """
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counter1", of: Counter.State.self) @_ComposedStateMember("counter2", of: Counter.State.self) @_ComposedStateMember("counters", of: IdentifiedArrayOf<Counter.State>.self) @_ComposedStateMember("optionalCounter", of: Counter.State?.self) @ObservableState
        struct State {
        }@_ComposedActionMember("counter1", of: Counter.Action.self) @_ComposedActionMember("counter2", of: Counter.Action.self) @_ComposedActionMember("counters", of: IdentifiedActionOf<Counter>.self) @_ComposedActionMember("optionalCounter", of: Counter.Action.self)

        enum Action {
          @ComposeAllCasePaths
          struct AllCasePaths {}

          static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.counter1, action: \Action.Cases.counter1) {
            Counter()
          }
          ComposableArchitecture.Scope(state: \.counter2, action: \Action.Cases.counter2) {
            Counter()
          }
          ComposableArchitecture.EmptyReducer()
          .forEach(\.counters, action: \Action.Cases.counters) {
            Counter()
          }
          .ifLet(\.optionalCounter, action: \Action.Cases.optionalCounter) {
            Counter()
          }
        }

        struct AllComposedScopePaths {
          var counter1: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.counter1, action: \Action.Cases.counter1)
            }
          }
          var counter2: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.counter2, action: \Action.Cases.counter2)
            }
          }
          var counters: TCAComposer.ScopePath<Feature.State, IdentifiedArrayOf<Counter.State>, Feature.Action, IdentifiedActionOf<Counter>> {
            get {
              return TCAComposer.ScopePath(state: \State.counters, action: \Action.Cases.counters)
            }
          }
          var optionalCounter: TCAComposer.ScopePath<Feature.State, Counter.State?, Feature.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.optionalCounter, action: \Action.Cases.optionalCounter)
            }
          }
        }
      }

      extension Action: CasePaths.CasePathable {
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
}

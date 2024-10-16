import MacroTesting
import XCTest

import TCAComposerMacros

final class EnumReducerMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeEnumReducerMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testEmptyNoArgs() {
    assertMacro {
      """
      @ComposeEnumReducer
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      """
      struct Empty {

          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: Equatable {

          }

          @CasePathable
          enum Action {

          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.EmptyReducer()
          }

          struct AllComposedScopeCases: TCAComposer.ScopeCases {
              typealias State = Empty.State
              typealias Action = Empty.Action

              @MainActor
              static func scopedState(store: StoreOf<Empty>) -> ScopedState {
                  switch store.state {

                  }
              }

              @CasePathable
              enum ScopedState: CasePaths.CasePathable  {

              }
          }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testComplex() {
    assertMacro {
      """
      @ComposeEnumReducer(
        children: [
          .reducer("counter1", of: Counter.self),
          .reducer("counter2", of: Counter.self, initialState: .init()),
          .state("someState", of: String.self),
          .state("someOtherState", of: String.self, initialValue: "foo"),
          .state("tupleState", of: (Int, String).self),
          .stateless("emptyState")
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      #"""
      struct Empty {

        @_ComposerScopeSwitchable
        @CasePathable
        @ObservableState
        @dynamicMemberLookup
        enum State: Equatable {
          case counter1(Counter.State)
          case counter2(Counter.State = .init())
          case someState(String)
          case someOtherState(String = "foo")
          case tupleState(Int, String)
          case emptyState
        }

        @CasePathable
        enum Action {
          case counter1(Counter.Action)
          case counter2(Counter.Action)
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
          var counter1: TCAComposer.ScopePath<Empty.State, Counter.State?, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.[dynamicMember: \.counter1], action: \Action.Cases.counter1)
            }
          }
          var counter2: TCAComposer.ScopePath<Empty.State, Counter.State?, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.[dynamicMember: \.counter2], action: \Action.Cases.counter2)
            }
          }
        }

        struct AllComposedScopeCases: TCAComposer.ScopeCases {
          typealias State = Empty.State
          typealias Action = Empty.Action

          @MainActor
          static func scopedState(store: StoreOf<Empty>) -> ScopedState {
            switch store.state {
            case .counter1:
              return .counter1(store: store.scope(state: \State.counter1, action: \Action.Cases.counter1)!)
            case .counter2:
              return .counter2(store: store.scope(state: \State.counter2, action: \Action.Cases.counter2)!)
            case let .someState(v0):
              return .someState(v0)
            case let .someOtherState(v0):
              return .someOtherState(v0)
            case let .tupleState(v0, v1):
              return .tupleState(v0, v1)
            case .emptyState:
              return .emptyState
            }
          }

          @CasePathable
          enum ScopedState: CasePaths.CasePathable  {
            case counter1(store: Store<Counter.State, Counter.Action>)
            case counter2(store: Store<Counter.State, Counter.Action>)
            case someState(String)
            case someOtherState(String)
            case tupleState(Int, String)
            case emptyState
          }
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testIfCaseLet() {
    assertMacro {
      """
      @ComposeEnumReducer(
        children: [
          .reducer("counter1", of: Counter.self),
          .reducer("counter2", of: Counter.self, initialState: .init()),
          .state("someState", of: String.self),
          .state("someOtherState", of: String.self, initialValue: "foo"),
          .state("tupleState", of: (Int, String).self),
          .stateless("emptyState")
        ]
      )
      @Composer
      struct Empty {
        @ComposeBody
        func reduce() -> EffectOf<Self> {
        }
      }
      """
    } expansion: {
      #"""
      struct Empty {
        @ComposeBody
        func reduce() -> EffectOf<Self> {
        }

        @_ComposerScopeSwitchable
        @CasePathable
        @ObservableState
        @dynamicMemberLookup
        enum State: Equatable {
          case counter1(Counter.State)
          case counter2(Counter.State = .init())
          case someState(String)
          case someOtherState(String = "foo")
          case tupleState(Int, String)
          case emptyState
        }

        @CasePathable
        enum Action {
          case counter1(Counter.Action)
          case counter2(Counter.Action)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.CombineReducers {
            ComposableArchitecture.Reduce { state, action in
              return self.reduce()
            }
          }
          .ifCaseLet(\.counter1, action: \Action.Cases.counter1) {
            Counter()
          }
          .ifCaseLet(\.counter2, action: \Action.Cases.counter2) {
            Counter()
          }
        }

        struct AllComposedScopePaths {
          var counter1: TCAComposer.ScopePath<Empty.State, Counter.State?, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.[dynamicMember: \.counter1], action: \Action.Cases.counter1)
            }
          }
          var counter2: TCAComposer.ScopePath<Empty.State, Counter.State?, Empty.Action, Counter.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.[dynamicMember: \.counter2], action: \Action.Cases.counter2)
            }
          }
        }

        struct AllComposedScopeCases: TCAComposer.ScopeCases {
          typealias State = Empty.State
          typealias Action = Empty.Action

          @MainActor
          static func scopedState(store: StoreOf<Empty>) -> ScopedState {
            switch store.state {
            case .counter1:
              return .counter1(store: store.scope(state: \State.counter1, action: \Action.Cases.counter1)!)
            case .counter2:
              return .counter2(store: store.scope(state: \State.counter2, action: \Action.Cases.counter2)!)
            case let .someState(v0):
              return .someState(v0)
            case let .someOtherState(v0):
              return .someOtherState(v0)
            case let .tupleState(v0, v1):
              return .tupleState(v0, v1)
            case .emptyState:
              return .emptyState
            }
          }

          @CasePathable
          enum ScopedState: CasePaths.CasePathable  {
            case counter1(store: Store<Counter.State, Counter.Action>)
            case counter2(store: Store<Counter.State, Counter.Action>)
            case someState(String)
            case someOtherState(String)
            case tupleState(Int, String)
            case emptyState
          }
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testTuplerStateWithInitialValue() {
    assertMacro {
      """
      @ComposeEnumReducer(
        children: [
          .state("tupleStateDefault", of: (Int, String).self, initialValue: (0, "")),
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeEnumReducer(
        children: [
          .state("tupleStateDefault", of: (Int, String).self, initialValue: (0, "")),
          ┬─────────────────────────────────────────────────────────────────────────
          ╰─ ⚠️ initialValue not supported with tuple state. Value will be ignored.
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      """
      struct Empty {

        @_ComposerScopeSwitchable
        @CasePathable
        @ObservableState
        @dynamicMemberLookup
        enum State: Equatable {
          case tupleStateDefault(Int, String)
        }

        @CasePathable
        enum Action {

        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
        }

        struct AllComposedScopeCases: TCAComposer.ScopeCases {
          typealias State = Empty.State
          typealias Action = Empty.Action

          @MainActor
          static func scopedState(store: StoreOf<Empty>) -> ScopedState {
            switch store.state {
            case let .tupleStateDefault(v0, v1):
              return .tupleStateDefault(v0, v1)
            }
          }

          @CasePathable
          enum ScopedState: CasePaths.CasePathable  {
            case tupleStateDefault(Int, String)
          }
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
}

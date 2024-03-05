import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposeReducerMacroTests: XCTestCase {
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
  
  func testEmptyNoArgs() {
    assertMacro {
      """
      @ComposeReducer
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      """
      struct Empty {

          @ObservableState
          struct State: Equatable {

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
  
  func testEmpty() {
    assertMacro {
      """
      @ComposeReducer()
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      """
      struct Empty {

          @ObservableState
          struct State: Equatable {

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
  
  func testHasStateActionAndBody() {
    assertMacro {
      """
      @ComposeReducer()
      @Composer
      struct Empty {
        struct State {}
        enum Action {}
        var body: some EffectOf<Self> {
          EmptyReducer()
        }
      }
      """
    } diagnostics: {
      """
      @ComposeReducer()
      @Composer
      struct Empty {
        struct State {}
        enum Action {}
        var body: some EffectOf<Self> {
        ╰─ ⚠️ @Composer `body` generation suppressed. Delete or rename `body` to enable.
          EmptyReducer()
        }
      }
      """
    } expansion: {
      """
      struct Empty {
        @ObservableState
        struct State {}
        @_ComposerCasePathable
        enum Action {}
        var body: some EffectOf<Self> {
          EmptyReducer()
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testBindableStateNoActionNoBody() {
    assertMacro {
      """
      @ComposeReducer(.bindable)
      @Composer
      struct Todo {
        struct State: Equatable, Identifiable {
          var description = ""
          let id: UUID
          var isComplete = false
        }
      }
      """
    } expansion: {
      """
      struct Todo {
        @ObservableState
        struct State: Equatable, Identifiable {
          var description = ""
          let id: UUID
          var isComplete = false
        }

        @CasePathable
        enum Action: ComposableArchitecture.BindableAction {
          case binding(BindingAction<State>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.BindingReducer()
        }
      }

      extension Todo: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  // NB: This has a formatting issue due to a regression in SwiftSyntax v510
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
          @_ComposedAction(.bindableAction) @_ComposerCasePathable @_ComposedActionMember("binding", of: BindingAction<State> .self)

          enum Action {
              @ComposeAllCasePaths
              struct AllCasePaths {}
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
              ComposableArchitecture.BindingReducer()
          }
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
      }
      """
    } expansion: {
      #"""
      struct Feature {

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
  
  func testSingleChildPublic() {
    assertMacro {
      """
      @ComposeReducer(
          children: [
              .reducer("counter", of: Counter.self)
          ]
      )
      @Composer
      public struct Feature {
      }
      """
    } expansion: {
      #"""
      public struct Feature {

          @ObservableState
          public struct State: Equatable, TCAComposer.ScopePathable {
              public var counter: Counter.State
              public  init() {
              }

              public static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          public enum Action {
              case counter(Counter.Action)
          }

          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          public var body: some ReducerOf<Self> {
              ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
                  Counter()
              }
          }

          public struct AllComposedScopePaths {
              public var counter: TCAComposer.ScopePath<Feature.State, Counter.State, Feature.Action, Counter.Action> {
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
      }
      """
    } expansion: {
      #"""
      struct Feature {

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              var counter1: Counter.State
              var counter2: Counter.State

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
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
      }
      """
    } expansion: {
      #"""
      struct Feature {

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              var optionalCounter: Counter.State?

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case optionalCounter(Counter.Action)
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
      }
      """
    } expansion: {
      #"""
      struct Feature {

          @ObservableState
          struct State: Equatable, TCAComposer.ScopePathable {
              var counters: IdentifiedArrayOf<Counter.State>

              static var allComposedScopePaths: AllComposedScopePaths {
                  AllComposedScopePaths()
              }
          }

          @CasePathable
          enum Action {
              case counters(IdentifiedActionOf<Counter>)
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
      }
      """
    } expansion: {
      #"""
      struct Feature {

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var counter1: Counter.State
          var counter2: Counter.State
          var counters: IdentifiedArrayOf<Counter.State>
          var optionalCounter: Counter.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case counter1(Counter.Action)
          case counter2(Counter.Action)
          case counters(IdentifiedActionOf<Counter>)
          case optionalCounter(Counter.Action)
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

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testAddsCasePathableToEnums() {
    assertMacro {
      """
      @ComposeReducer()
      @Composer
      struct Feature {
        enum DelegateAction {
        }
        enum EffectAction {
        }
        enum DelegateAction {
        }
      }
      """
    } expansion: {
      """
      struct Feature {
        @CasePathable
        enum DelegateAction {
        }
        @CasePathable
        enum EffectAction {
        }
        @CasePathable
        enum DelegateAction {
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

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
  
  func testAddsCasePathableToEnumsOnlyIfNeeded() {
    assertMacro {
      """
      @ComposeReducer()
      @Composer
      struct Feature {
        @CasePathable
        enum DelegateAction {
        }
        enum EffectAction: CasePathable {
        }
        enum ViewAction {
        }
        enum RandomEnum {
        }
      }
      """
    } expansion: {
      """
      struct Feature {
        @CasePathable
        enum DelegateAction {
        }
        enum EffectAction: CasePathable {
        }
        @CasePathable
        enum ViewAction {
        }
        enum RandomEnum {
        }

        @ObservableState
        struct State: Equatable {

        }

        @CasePathable
        enum Action {

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
}

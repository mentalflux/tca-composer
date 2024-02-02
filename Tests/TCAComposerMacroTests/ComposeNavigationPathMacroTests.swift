import MacroTesting
import XCTest
import TCAComposerMacros

final class ComposeNavigationPathMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self
              ]
    ) {
      super.invokeTest()
    }
  }
  
  func testEmpty() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .navigationStack()
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
          var path: StackState<Path.State> = .init()

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case path(StackAction<Path.State, Path.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        struct AllComposedScopePaths {
          var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
        }

        struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {

          }
          @CasePathable
          enum Action: CasePaths.CasePathable {

          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.EmptyReducer()
          }
          struct AllComposedScopeCases: TCAComposer.ScopeCases {
            typealias State = Path.State
            typealias Action = Path.Action

            static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {

              }
            }

            @CasePathable
            enum ScopedState {

            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testReducerChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .reducer("counter", of: Counter.self)
            ]
          )
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
          var path: StackState<Path.State> = .init()

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case path(StackAction<Path.State, Path.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        struct AllComposedScopePaths {
          var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
        }

        struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {
            case counter(Counter.State)
          }
          @CasePathable
          enum Action: CasePaths.CasePathable {
            case counter(Counter.Action)
          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
              Counter()
            }
          }
          struct AllComposedScopeCases: TCAComposer.ScopeCases {
            typealias State = Path.State
            typealias Action = Path.Action

            static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {
              case .counter:
                return .counter(store: store.scope(state: \State.counter, action: \Action.Cases.counter)!)
              }
            }

            @CasePathable
            enum ScopedState {
              case counter(store: Store<Counter.State, Counter.Action>)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testStateChild() {
    assertMacro {
      """
      struct SomeState {
      }
      
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .state("counter", of: SomeState.self)
            ]
          )
        ]
      )
      @Composer
      struct Feature {
      }
      """
    } expansion: {
      #"""
      struct SomeState {
      }
      struct Feature {

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var path: StackState<Path.State> = .init()

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case path(StackAction<Path.State, Path.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        struct AllComposedScopePaths {
          var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
        }

        struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {
            case counter(SomeState)
          }
          @CasePathable
          enum Action: CasePaths.CasePathable {

          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.EmptyReducer()
          }
          struct AllComposedScopeCases: TCAComposer.ScopeCases {
            typealias State = Path.State
            typealias Action = Path.Action

            static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {
              case let .counter(v0):
                return .counter(v0)
              }
            }

            @CasePathable
            enum ScopedState {
              case counter(SomeState)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testStateTupleChild() {
    assertMacro {
      """
      struct SomeState {
      }
      struct SomeOtherState {
      }
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .state("counter", of: (SomeState, other: SomeOtherState).self)
            ]
          )
        ]
      )
      @Composer
      struct Feature {
      }
      """
    } expansion: {
      #"""
      struct SomeState {
      }
      struct SomeOtherState {
      }
      struct Feature {

        @ObservableState
        struct State: Equatable, TCAComposer.ScopePathable {
          var path: StackState<Path.State> = .init()

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case path(StackAction<Path.State, Path.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        struct AllComposedScopePaths {
          var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
        }

        struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {
            case counter(SomeState, other: SomeOtherState)
          }
          @CasePathable
          enum Action: CasePaths.CasePathable {

          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.EmptyReducer()
          }
          struct AllComposedScopeCases: TCAComposer.ScopeCases {
            typealias State = Path.State
            typealias Action = Path.Action

            static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {
              case let .counter(v0, other: v1):
                return .counter(v0, other: v1)
              }
            }

            @CasePathable
            enum ScopedState {
              case counter(SomeState, other: SomeOtherState)
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
            .navigationStack(
                children: [
                    .reducer("detail", of: SyncUpDetail.self),
                    .state("meeting", of: (Meeting, syncUp: SyncUp).self),
                    .reducer("record", of: RecordMeeting.self)
                ]
            ),
            .reducer("syncUpsList", of: SyncUpsList.self, initialState: .init())
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
          var path: StackState<Path.State> = .init()
          var syncUpsList: SyncUpsList.State = .init()

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case path(StackAction<Path.State, Path.Action>)
          case syncUpsList(SyncUpsList.Action)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.syncUpsList, action: \Action.Cases.syncUpsList) {
            SyncUpsList()
          }
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        struct AllComposedScopePaths {
          var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
          var syncUpsList: TCAComposer.ScopePath<Feature.State, SyncUpsList.State, Feature.Action, SyncUpsList.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.syncUpsList, action: \Action.Cases.syncUpsList)
            }
          }
        }

        struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {
            case detail(SyncUpDetail.State)
            case meeting(Meeting, syncUp: SyncUp)
            case record(RecordMeeting.State)
          }
          @CasePathable
          enum Action: CasePaths.CasePathable {
            case detail(SyncUpDetail.Action)
            case record(RecordMeeting.Action)
          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.Scope(state: \.detail, action: \Action.Cases.detail) {
              SyncUpDetail()
            }
            ComposableArchitecture.Scope(state: \.record, action: \Action.Cases.record) {
              RecordMeeting()
            }
          }
          struct AllComposedScopeCases: TCAComposer.ScopeCases {
            typealias State = Path.State
            typealias Action = Path.Action

            static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {
              case .detail:
                return .detail(store: store.scope(state: \State.detail, action: \Action.Cases.detail)!)
              case let .meeting(v0, syncUp: v1):
                return .meeting(v0, syncUp: v1)
              case .record:
                return .record(store: store.scope(state: \State.record, action: \Action.Cases.record)!)
              }
            }

            @CasePathable
            enum ScopedState {
              case detail(store: Store<SyncUpDetail.State, SyncUpDetail.Action>)
              case meeting(Meeting, syncUp: SyncUp)
              case record(store: Store<RecordMeeting.State, RecordMeeting.Action>)
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testPublicReducerChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .reducer("counter", of: Counter.self)
            ]
          )
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
          public var path: StackState<Path.State> = .init()
          public  init() {
          }

          public static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        public enum Action {
          case path(StackAction<Path.State, Path.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        public var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .forEach(\.path, action: \Action.Cases.path) {
            Path()
          }
        }

        public struct AllComposedScopePaths {
          public var path: TCAComposer.ScopePath<Feature.State, StackState<Path.State>, Feature.Action, StackAction<Path.State, Path.Action>> {
            get {
              return TCAComposer.ScopePath(state: \State.path, action: \Action.Cases.path)
            }
          }
        }

        public struct Path: ComposableArchitecture.Reducer {
          @_ComposerScopeSwitchable
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          public enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable, TCAComposer.ScopeSwitchable {
            case counter(Counter.State)
          }
          @CasePathable
          public enum Action: CasePaths.CasePathable {
            case counter(Counter.Action)
          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          public var body: some ReducerOf<Self> {
            ComposableArchitecture.Scope(state: \.counter, action: \Action.Cases.counter) {
              Counter()
            }
          }
          public struct AllComposedScopeCases: TCAComposer.ScopeCases {
            public typealias State = Path.State
            public typealias Action = Path.Action

            public static func scopedState(store: StoreOf<Path>) -> ScopedState {
              switch store.state {
              case .counter:
                return .counter(store: store.scope(state: \State.counter, action: \Action.Cases.counter)!)
              }
            }

            @CasePathable
            public enum ScopedState {
              case counter(store: Store<Counter.State, Counter.Action>)
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

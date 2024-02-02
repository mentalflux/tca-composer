import MacroTesting
import XCTest
import TCAComposerMacros

final class ComposeNavigationDestinationMacroTests: XCTestCase {
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
          .presentsDestination()
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
          @Presents var destination: Destination.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case destination(PresentationAction<Destination.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$destination, action: \Action.Cases.destination) {
            Destination()
          }
        }

        struct AllComposedScopePaths {
          var destination: Destination.AllComposedScopePaths {
            get {
              return Destination.AllComposedScopePaths()
            }
          }
        }

        struct Destination: ComposableArchitecture.Reducer {
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable {

          }
          @CasePathable
          enum Action: CasePaths.CasePathable {

          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.EmptyReducer()
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
          .presentsDestination(
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
          @Presents var destination: Destination.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case destination(PresentationAction<Destination.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$destination, action: \Action.Cases.destination) {
            Destination()
          }
        }

        struct AllComposedScopePaths {
          var destination: Destination.AllComposedScopePaths {
            get {
              return Destination.AllComposedScopePaths()
            }
          }
        }

        struct Destination: ComposableArchitecture.Reducer {
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable {
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
          struct AllComposedScopePaths {
            var counter: TCAComposer.ScopePath<Feature.State, Counter.State?, Feature.Action, PresentationAction<Counter.Action>> {
              get {
                return TCAComposer.ScopePath(state: \Feature.State.destination?.counter, action: \Feature.Action.Cases.destination.counter)
              }
            }
          }
        }
      }

      extension Feature: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testAlertChild() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .presentsDestination(
            children: [
              .alert()
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
          @Presents var destination: Destination.State?

          static var allComposedScopePaths: AllComposedScopePaths {
            AllComposedScopePaths()
          }
        }

        @CasePathable
        enum Action {
          case destination(PresentationAction<Destination.Action>)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.EmptyReducer()
          .ifLet(\.$destination, action: \Action.Cases.destination) {
            Destination()
          }
        }

        struct AllComposedScopePaths {
          var destination: Destination.AllComposedScopePaths {
            get {
              return Destination.AllComposedScopePaths()
            }
          }
        }

        struct Destination: ComposableArchitecture.Reducer {
          @CasePathable
          @ObservableState
          @dynamicMemberLookup
          enum State: CasePaths.CasePathable, ComposableArchitecture.ObservableState, Equatable {
            case alert(AlertState<Never>)
          }
          @CasePathable
          enum Action: CasePaths.CasePathable {
            case alert(Never)
          }
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            ComposableArchitecture.EmptyReducer()
          }
          struct AllComposedScopePaths {
            var alert: TCAComposer.ScopePath<Feature.State, AlertState<Never>?, Feature.Action, PresentationAction<Never>> {
              get {
                return TCAComposer.ScopePath(state: \Feature.State.destination?.alert, action: \Feature.Action.Cases.destination.alert)
              }
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

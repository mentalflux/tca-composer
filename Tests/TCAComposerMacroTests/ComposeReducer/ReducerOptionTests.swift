import MacroTesting
import XCTest
import TCAComposerMacros

final class ReducerOptionTests: XCTestCase {
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
  
  func testNoOptions() {
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
  
  func testBindable() {
    assertMacro {
      """
      @ComposeReducer(
        .bindable
      )
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
        enum Action: ComposableArchitecture.BindableAction {
          case binding(BindingAction<State>)
        }
      
        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.BindingReducer()
        }
      }
      
      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testStateNoOptions() {
    assertMacro {
      """
      @ComposeReducer(
        .state()
      )
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
  
  func testStateNotEquatable() {
    assertMacro {
      """
      @ComposeReducer(
        .state(.notEquatable)
      )
      @Composer
      struct Empty {
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
  
  func testAllConformances() {
    assertMacro {
      """
      @ComposeReducer(
        .action(.hashable, .equatable, .sendable),
        .state(.codable, .hashable, .sendable)
      )
      @Composer
      struct Empty {
      }
      """
    } expansion: {
      """
      struct Empty {

        @ObservableState
        struct State: Codable, Equatable, Hashable, Sendable {

        }

        @CasePathable
        enum Action: Equatable, Hashable, Sendable {

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
}

import MacroTesting
import XCTest
import TCAComposerMacros

final class EnumeratedReducerOptionTests: XCTestCase {
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
  
  func testInitialStateCaseStateless() {
    assertMacro {
      """
      @ComposeEnumReducer(
        .initialStateCase("emptyState"),
        children: [
          .stateless("emptyState")
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
          case emptyState
          init() {
            self = .emptyState
          }
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

          static func scopedState(store: StoreOf<Empty>) -> ScopedState {
            switch store.state {
            case .emptyState:
              return .emptyState
            }
          }

          @CasePathable
          enum ScopedState {
            case emptyState
          }
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """
    }
  }
  
  func testInitialStateCaseReducerWithInitialValue() {
    assertMacro {
      """
      @ComposeEnumReducer(
        .initialStateCase("feature"),
        children: [
          .reducer("feature", of: Feature.self, initialState: .init())
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
          case feature(Feature.State = .init())
          init() {
            self = .feature()
          }
        }

        @CasePathable
        enum Action {
          case feature(Feature.Action)
        }

        @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
        var body: some ReducerOf<Self> {
          ComposableArchitecture.Scope(state: \.feature, action: \Action.Cases.feature) {
            Feature()
          }
        }

        struct AllComposedScopePaths {
          var feature: TCAComposer.ScopePath<Empty.State, Feature.State?, Empty.Action, Feature.Action> {
            get {
              return TCAComposer.ScopePath(state: \State.[dynamicMember: \.feature], action: \Action.Cases.feature)
            }
          }
        }

        struct AllComposedScopeCases: TCAComposer.ScopeCases {
          typealias State = Empty.State
          typealias Action = Empty.Action

          static func scopedState(store: StoreOf<Empty>) -> ScopedState {
            switch store.state {
            case .feature:
              return .feature(store: store.scope(state: \State.feature, action: \Action.Cases.feature)!)
            }
          }

          @CasePathable
          enum ScopedState {
            case feature(store: Store<Feature.State, Feature.Action>)
          }
        }
      }

      extension Empty: ComposableArchitecture.Reducer {
      }
      """#
    }
  }
  
  func testInitialStateCaseInvalidName() {
    assertMacro {
      """
      @ComposeEnumReducer(
        .initialStateCase("invalid"),
        children: [
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeEnumReducer(
        .initialStateCase("invalid"),
                          ┬────────
                          ╰─ 🛑 'invalid' is not a valid initialStateCase name.
        children: [
        ]
      )
      @Composer
      struct Empty {
      }
      """
    }
  }
  
  func testInitialStateCaseNoInitialValue() {
    assertMacro {
      """
      @ComposeEnumReducer(
        .initialStateCase("featureA"),
        children: [
          .reducer("featureA", of: FeatureA.self),
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeEnumReducer(
        .initialStateCase("featureA"),
                          ┬─────────
                          ╰─ 🛑 'featureA' does not have a default value and cannot be used for an `initialStateCase`.
      "Add an initialValue to `'featureA' to resolve.
        children: [
          .reducer("featureA", of: FeatureA.self),
        ]
      )
      @Composer
      struct Empty {
      }
      """
    }
  }
}

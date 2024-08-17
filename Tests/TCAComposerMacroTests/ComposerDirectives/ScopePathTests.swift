import MacroTesting
import XCTest

import TCAComposerMacros

final class ScopePathTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [ComposerMacro.self,
               ComposeReducerMacro.self,
               ComposeScopePathMacro.self,
              ]
    ) {
      super.invokeTest()
    }
  }
  
  // NB: This has a formatting issue due to a regression in SwiftSyntax v510
  func testScopePath() {
    assertMacro {
      #"""
      @ComposeReducer(
          children: [
              .identifiedArray("counters", of: Counter.self),
          ]
      )
      @Composer
      struct Feature {
        struct State {
          var filter: Filter
      
          @ComposeScopePath(action: \Action.Cases.counters)
          var filteredCounters: IdentifiedArrayOf<Counter.State> {
            switch filter {
            case .all: return self.counters
            case .even: return self.counters.filter({ $.count % 2 == 0 })
            case .odd: return self.counters.filter({ $.count % 2 != 0 })
            }
          }
        }
      }
      """#
    } expansion: {
      #"""
      struct Feature {
        @_ComposerScopePathable @_ComposedStateMember("counters", of: IdentifiedArrayOf<Counter.State>.self) @ObservableState
        struct State {
          var filter: Filter
          var filteredCounters: IdentifiedArrayOf<Counter.State> {
            switch filter {
            case .all: return self.counters
            case .even: return self.counters.filter({ $.count % 2 == 0 })
            case .odd: return self.counters.filter({ $.count % 2 != 0 })
            }
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
              var filteredCounters: TCAComposer.ScopePath<Feature.State, IdentifiedArrayOf<Counter.State>, Feature.Action, IdentifiedActionOf<Counter>> {
                  get {
                      return TCAComposer.ScopePath(state: \State.filteredCounters, action: \Action.Cases.counters)
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

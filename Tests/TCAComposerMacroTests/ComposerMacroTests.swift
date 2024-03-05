import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposerMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [
        ComposerMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }
  
  func testBasics() {
    assertMacro {
      """
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
  
  func testReducerMacroDiagnostic() {
    assertMacro {
      """
      @Composer
      @Reducer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @Composer
      @Reducer
      ┬───────
      ╰─ 🛑 @Reducer cannot be used in combination with @Composer.
         ✏️ Remove @Reducer.
      struct Empty {
      }
      """
    } fixes: {
      """
      @Composer
      struct Empty {
      }
      """
    }expansion: {
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
  
  func testEmptyNoArgsEnum() {
    assertMacro {
      """
      @Composer
      enum Empty {
      }
      """
    } diagnostics: {
      """
      @Composer
      ┬────────
      ╰─ 🛑 @Composer can only be applied to struct declarations.
      enum Empty {
      }
      """
    }
  }
}

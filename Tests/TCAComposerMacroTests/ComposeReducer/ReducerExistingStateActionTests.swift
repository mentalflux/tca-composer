import MacroTesting
import XCTest

import TCAComposerMacros

final class ReducerExistingStateActionTests: XCTestCase {
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
    } diagnostics: {
      """
      @Composer
      struct Empty {
        struct State {
        }

        enum Action {
        ╰─ 🛑 @Composer automatically generates the `Action` enum, please rename or remove.
        }
      }
      """
    } 
  }
  
}

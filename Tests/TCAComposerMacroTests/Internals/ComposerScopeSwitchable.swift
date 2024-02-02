import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposerScopeSwitchableMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
//            isRecording: true,
            macros: [_ComposerScopeSwitchableMacro.self]
        ) {
            super.invokeTest()
        }
    }
    
    func testBasics() {
        assertMacro {
            """
            @_ComposerScopeSwitchable
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                public static var allComposedScopeCases: AllComposedScopeCases {
                    AllComposedScopeCases()
                }
            }

            extension State: TCAComposer.ScopeSwitchable {
            }
            """
        }
    }
}

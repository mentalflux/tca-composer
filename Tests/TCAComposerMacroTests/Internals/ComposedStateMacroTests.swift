import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposedStateMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
//            isRecording: true,
            macros: [_ComposerScopePathableMacro.self]
        ) {
            super.invokeTest()
        }
    }
    
    func testBasics() {
        assertMacro {
            """
            @_ComposerScopePathable
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                public static var allComposedScopePaths: AllComposedScopePaths {
                    AllComposedScopePaths()
                }
            }

            extension State: TCAComposer.ScopePathable {
            }
            """
        }
    }
}

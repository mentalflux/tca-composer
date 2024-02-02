
import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposedActionMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
//            isRecording: true,
            macros: [_ComposedActionMacro.self]
        ) {
            super.invokeTest()
        }
    }
    
    func testEmpty() {
        assertMacro {
            """
            @_ComposedAction
            struct Action {
            }
            """
        } expansion: {
            """
            struct Action {
            }
            """
        }
    }

    func testBindableAction() {
        assertMacro {
            """
            @_ComposedAction(.bindableAction)
            struct Action {
            }
            """
        } expansion: {
            """
            struct Action {
            }

            extension Action: ComposableArchitecture.BindableAction {
            }
            """
        }
    }
    
    func testViewAction() {
        assertMacro {
            """
            @_ComposedAction(.viewAction)
            struct Action {
            }
            """
        } expansion: {
            """
            struct Action {
            }

            extension Action: ComposableArchitecture.ViewAction {
            }
            """
        }
    }
    
    func testViewAndBindableAction() {
        assertMacro {
            """
            @_ComposedAction(.bindableAction, .viewAction)
            struct Action {
            }
            """
        } expansion: {
            """
            struct Action {
            }

            extension Action: ComposableArchitecture.BindableAction {
            }

            extension Action: ComposableArchitecture.ViewAction {
            }
            """
        }
    }
    
    // NB: This shouldn't happen in actual real-world usage, just an internal check to veriy it is ignore.
    func testUnknownOption() {
        assertMacro {
            """
            @_ComposedAction(.unknown)
            struct Action {
            }
            """
        } expansion: {
            """
            struct Action {
            }
            """
        }
    }
}

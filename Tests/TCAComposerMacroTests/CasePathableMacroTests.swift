#if canImport(TCAComposerMacros)
import MacroTesting
import XCTest

import TCAComposerMacros

final class CasePathableMacroTests: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
//      isRecording: true,
      macros: [
        ComposeAllCasePathsMacro.self,
        _ComposerCasePathableMacro.self,
        _ComposedActionMemberMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }
  
  func testNoGeneratedCasePaths() {
    assertMacro {
      """
      @_ComposerCasePathable
      enum Action {
        case buttonClicked
      }
      """
    } expansion: {
      """
      enum Action {
        case buttonClicked

        struct AllCasePaths {
          var buttonClicked: CasePaths.AnyCasePath<Action, Void> {
            CasePaths.AnyCasePath<Action, Void>(
              embed: {
                Action.buttonClicked
              },
              extract: {
                guard case .buttonClicked = $0 else {
                  return nil
                }
                return ()
              }
            )
          }
        }

        static var allCasePaths: AllCasePaths {
          AllCasePaths()
        }
      }

      extension Action: CasePaths.CasePathable {
      }
      """
    }
  }
  
  func testExistingCaseWithGeneration() {
    assertMacro {
      """
      @_ComposerCasePathable
      enum Action {
        case incrementTapped
        case counter(Counter.Action)
        case counters(id: Counter.ID, action: Counter.Action)

        @ComposeAllCasePaths
        struct AllCasePaths {}
      }
      """
    } expansion: {
      """
      enum Action {
        case incrementTapped
        case counter(Counter.Action)
        case counters(id: Counter.ID, action: Counter.Action)
        @_ComposedCasePathMember(enumName: "Action", caseName: "incrementTapped", of: Void.self) @_ComposedCasePathMember(enumName: "Action", caseName: "counter", of: Counter.Action.self) @_ComposedCasePathMember(enumName: "Action", caseName: "counters", of: (id: Counter.ID, action: Counter.Action).self)
        struct AllCasePaths {}

        static var allCasePaths: AllCasePaths {
          AllCasePaths()
        }
      }

      extension Action: CasePaths.CasePathable {
      }
      """
    }
  }
  
  func testCombinedCase() {
    assertMacro {
      """
      @_ComposerCasePathable
      @_ComposedActionMember("child", of: Child.Action.self)
      enum SomeAction {
        case incrementTapped
      
        @ComposeAllCasePaths
        struct AllCasePaths {}
      }
      """
    } expansion: {
      """
      enum SomeAction {
        case incrementTapped
        @_ComposedCasePathMember(enumName: "SomeAction", caseName: "incrementTapped", of: Void.self)
        @_ComposedCasePathMember(enumName: "SomeAction", caseName: "child", of: Child.Action.self)
        struct AllCasePaths {}

        static var allCasePaths: AllCasePaths {
          AllCasePaths()
        }

        case child(Child.Action)
      }

      extension SomeAction: CasePaths.CasePathable {
      }
      """
    }
  }
  
}
#endif

import MacroTesting
import XCTest
import TCAComposerMacros

final class ReducerDiagnosticTests: XCTestCase {
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
  
  func testDuplicateChildName() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self),
          .reducer("counter", of: Counter.self)
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeReducer(
        children: [
          .reducer("counter", of: Counter.self),
          .reducer("counter", of: Counter.self)
                   ┬────────
                   ╰─ 🛑 Duplicate definition of a child named 'counter'.
        ]
      )
      @Composer
      struct Empty {
      }
      """
    }
  }
  
  func testDuplicateDestinationChildName() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .presentsDestination(
            children: [
              .reducer("counter", of: Counter.self),
              .reducer("counter", of: Counter.self)
            ]
          )
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeReducer(
        children: [
          .presentsDestination(
            children: [
              .reducer("counter", of: Counter.self),
              .reducer("counter", of: Counter.self)
                       ┬────────
                       ╰─ 🛑 Duplicate definition of a child named 'destination.counter'.
            ]
          )
        ]
      )
      @Composer
      struct Empty {
      }
      """
    }
  }
  
  func testDuplicateStackChildName() {
    assertMacro {
      """
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .reducer("counter", of: Counter.self),
              .reducer("counter", of: Counter.self)
            ]
          )
        ]
      )
      @Composer
      struct Empty {
      }
      """
    } diagnostics: {
      """
      @ComposeReducer(
        children: [
          .navigationStack(
            children: [
              .reducer("counter", of: Counter.self),
              .reducer("counter", of: Counter.self)
                       ┬────────
                       ╰─ 🛑 Duplicate definition of a child named 'path.counter'.
            ]
          )
        ]
      )
      @Composer
      struct Empty {
      }
      """
    }
  }
}

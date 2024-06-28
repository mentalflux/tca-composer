import XCTest
import ComposableArchitecture

@testable import TCAComposer

final class ComposerTests: XCTestCase {
  
  @Composer
  struct Child {
    struct State: Equatable {
      var count: Int
    }
  }
  
  @ComposeReducer(
    children: [
      .reducer("child", of: Child.self)
    ]
  )
  @Composer
  struct Parent {
    
  }
  
  func testKeyPathsExistingAction() throws {
    // Verify these all compiile
    let _ = \Parent.Action.Cases.child
    let _ = \Parent.State.child.count
  }
}

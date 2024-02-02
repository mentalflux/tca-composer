import XCTest
import ComposableArchitecture

@testable import TCAComposer

final class ComposerTests: XCTestCase {
  
  @Composer
  struct Child {
    struct State: Equatable {
      var count: Int
    }
    enum Action {
      
    }
  }
  
  @ComposeReducer(
    children: [
      .reducer("child", of: Child.self)
    ]
  )
  @Composer
  struct Parent {
    
    enum Action {
      @ComposeAllCasePaths
      struct AllCasePaths {}
    }
  }
  
  func testKeyPathsExistingAction() throws {
    // Verify these all compiile
    let _ = \Parent.Action.Cases.child
    let _ = \Parent.State.child.count
  }
}

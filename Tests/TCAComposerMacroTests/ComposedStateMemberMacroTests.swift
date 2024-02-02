
import MacroTesting
import XCTest

import TCAComposerMacros

final class ComposedStateMemberMacroTests: XCTestCase {
    override func invokeTest() {
        withMacroTesting(
//            isRecording: true,
            macros: [_ComposedStateMemberMacro.self]
        ) {
            super.invokeTest()
        }
    }
    
    func testSimple() {
        assertMacro {
            """
            @_ComposedStateMember("counter", of: Counter.self)
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                @ObservationStateTracked
                var counter: Counter

                @ObservationStateIgnored
                private var _counter: Counter
            }
            """
        }
    }
    
    func testSimplePublic() {
        assertMacro {
            """
            @_ComposedStateMember("counter", of: Counter.self)
            public struct State {
            }
            """
        } expansion: {
            """
            public struct State {

                @ObservationStateTracked
                public var counter: Counter

                @ObservationStateIgnored
                private var _counter: Counter
            }
            """
        }
    }
    
    func testSimpleInitialValue() {
        assertMacro {
            """
            @_ComposedStateMember("counter", of: Counter.self, initialValue: .init())
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                @ObservationStateTracked
                var counter: Counter = .init()

                @ObservationStateIgnored
                private var _counter: Counter
            }
            """
        }
    }
    
    func testComplexInitialValue() {
        assertMacro {
            """
            @_ComposedStateMember("counter", of: Counter.self, initialValue: Counter(count: 42))
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                @ObservationStateTracked
                var counter: Counter = Counter(count: 42)

                @ObservationStateIgnored
                private var _counter: Counter
            }
            """
        }
    }
    
    func testIdentifiedArrayDefaultInitialValue() {
        assertMacro {
            """
            @_ComposedStateMember("counters", of: IdentifiedArrayOf<Counter>.self)
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                @ObservationStateTracked
                var counters: IdentifiedArrayOf<Counter> = []

                @ObservationStateIgnored
                private var _counters: IdentifiedArrayOf<Counter>
            }
            """
        }
    }
    
    func testIdentifiedArrayInitialValue() {
        assertMacro {
            """
            @_ComposedStateMember("counters", of: IdentifiedArrayOf<Counter>.self, initialValue: [Counter(count: 42)])
            struct State {
            }
            """
        } expansion: {
            """
            struct State {

                @ObservationStateTracked
                var counters: IdentifiedArrayOf<Counter> = [Counter(count: 42)]

                @ObservationStateIgnored
                private var _counters: IdentifiedArrayOf<Counter>
            }
            """
        }
    }
    
    func testPresents() {
        assertMacro {
          """
          @_ComposedStateMember("counter", of: AlertState<AlertAction>?.self, options: .presents)
          struct State {
          }
          """
        } expansion: {
            """
            struct State {

                @Presents
                var counter: AlertState<AlertAction>?
            }
            """
        }
    }
    
}


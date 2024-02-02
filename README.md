# TCA Composer

[![CI](https://github.com/mentalflux/tca-composer/actions/workflows/ci.yml/badge.svg)](https://github.com/mentalflux/tca-composer/actions/workflows/ci.yml)

TCA Composer is a swift macro framework for eliminating boiler-plate code in [TCA-based](https://github.com/pointfreeco/swift-composable-architecture) applications. Composer provides a collection of swift macros that allow you to declaritively construct a `Reducer` and automaticaly generate all or portions of the `State`, `Action`, and `body` declarations. Composer can also automatically generate an entire `Reducer` for use in navigation destinations and stacks. Composer encourages simple design patterns to structure your code, while still allowing you complete flexibility in how to structure your code and application.

> [!Important]
> Composer requires version 1.7.0 (or later) of The Composable Architecture. Composer also requires the adoption of `ObservableState` in your `Reducer`.
> If you are migrating an existing `Reducer` to Composer, it is highly recommended that you first update your `Reducer` to use `ObservableState` by following the [migration guide](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.7) to make a transition to 
> using Composer much smoother.

* [Examples](#examples)
* [Basic Usage](#basic-usage)
* [Improved View Ergonomics](#improved-view-ergonomics)
* [Documentation](#documentation)
* [Known Issues](#known-issues)

## Examples

This repository includes several examples from the [TCA repo](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples) that have been converted to use the Composer macro framework, including:

* [SyncUps app](https://github.com/mentalflux/tca-composer/tree/main/Examples/SyncUps)
* [Todos](https://github.com/mentalflux/tca-composer/tree/main/Examples/Todos)
* [Voice memos](https://github.com/mentalflux/tca-composer/tree/main/Examples/VoiceMemos)

The examples are a great way to get started and experiment with Composer.

## Basic Usage

### Getting Started

Let's start with creating the canoncial TCA example, `Counter`. To use Composer, add the package to your project and import the `TCAComposer` module. Then replace the `@Reducer` macro with the `@Composer` macro in the `Counter` declaration as follows. That's all that is requried to start composing. In fact, the following code already compiles. 

```diff
 import ComposableArchitecture
+import TCAComposer

-@Reducer
+@Composer
 struct Counter {
 }
```

<details>
<summary>

#### Let's see what code was generated. Click to expand the `@Composer` macro

</summary>

```diff
 import ComposableArchitecture
 import TCAComposer

 @Composer
 struct Counter {
+  @ObservableState 
+  struct State: Equatable {
+  }
+
+  @CasePathable
+  enum Action {
+  }
+
+  @ReducerBuilder<State, Action>
+  var body: some ReducerOf<Self> {
+    EmptyReducer()
+  }
}
```

Using the `@Composer` macro has already created a fully functional `Reducer`. Of course, it doesn't do anything yet. So let's change that. 

</details>

### Creating the `State` for a Simple Counter

Let's go ahead and build the simple Counter example frequently used in TCA. To do that, we just add 

```swift
@Composer
struct Counter {
  struct State {
    var count = 0
  }
}
```

<details>
<summary>

#### Let's see what code was generated. Click to expand the `@Composer` macro

</summary>
    
```diff
 @Composer
 struct Counter {
+  @ObservableState 
   struct State {
     var count = 0
   }
+
+  @CasePathable
+  enum Action {
+  }
+
+  @ReducerBuilder<State, Action>
+  var body: some ReducerOf<Self> {
+    EmptyReducer()
+  }
}
```

Composer automatically applies `@ObservableState` to all of your `State` declarations if it is missing.

</details>

### Creating the `Action` for a Simple Counter

Now that we have our `State` implemented, let's implement the `Action`. This is where creating a `Reducer` using Composer starts to get interesting. Composer is designed to take full responsiblity for generating the `Action` for a `Reducer`. Instead of creating one large `Action` enum in your code, Composer encourages you to break `Action` into smaller domain specific actions. This is a common design pattern used within the [TCA Community](https://www.merowing.info/boundries-in-tca/).

> Note: If you want to manage `Action` yourself, you can still use Composer. But you will need to add some boiler-plate to your `Action` to make full use of Composer's capabilities.
> The documentation provides more details on how to accomplish this.

Now, let's implement the ability to increment and decrement the count by creating two actions `decrementButtonTapped` and `incrementButtonTapped`. In a normal TCA application you would create an `Action` enum and add the two cases. In Composer, we are instead going to name our enum `ViewAction` instead. 

> Note: The name `ViewAction` is chosen by convention. You are free to chose any name and structure your code in any way you like (including nested enums) with Composer.
> Composer does have certain preferred conventions and if you adopt them you will be given some additional benefits such as the automatic addition of `@CasePathable` to action enums,
> but you are not obligated to do so.

```diff
 @Composer
 struct Counter {
   struct State {
     var count = 0
   }

-  enum Action {
+  enum ViewAction {
     case decrementButtonTapped
     case incrementButtonTapped
   }
 }
```

<details>
<summary>

#### Let's see what code was generated. Click to expand the `@Composer` macro

</summary>
    
```diff
 @Composer
 
 struct Counter {
+  @ObservableState 
   struct State {
     var count = 0
   }

+  @CasePathable
   enum ViewAction {
     case decrementButtonTapped
     case incrementButtonTapped
   }
+
+  @CasePathable
+  enum Action {
+  }
+
+  @ReducerBuilder<State, Action>
+  var body: some ReducerOf<Self> {
+    EmptyReducer()
+  }
}
```

Composer has automatically applied `@CasePathable` to our `ViewAction` enum. By default, Composer will automatically apply `@CasePathable` to any enum defined in your reducer that has a suffix of `Action` in its name. But, Composer hasn't done anything interesting with the `Action` yet. Let's move on to creating the `body` and see what is different.

</details>

### Creating the Reducer `body` for a Simple Counter

Normally, all the interesting work of a `Reducer` happens in the `body` declaration. It is very common for applications to have very large and complex `body` declarations. Just as with `Action`, Composer encourages you to break your reducer into smaller pieces and takes full resposiblity for generating the `body` for a `Reducer`.  To accomplish this, Composer needs some guidance from you in the form of directives. Directives are macros that you attach to portions of code in you reducer to direct Composer how to compose the `body` and `Action` of your reducer. All directives begin with `@Compose...`, and directives that affect the composition of the `body` begin with `@ComposeBody...`.

> Note: `@Compose...` directives do not generate any code and cannot be expanded in XCode. They are merely annotations read by the `@Composer` macro to determine what code to generate.

Continuing with our `Counter` example. Instead of writing a `body` for our `Reducer` we are going to delegate that to Composer. Instead, we are going to add a function to reduce the `ViewAction` directly and we are going to instruct Composer how to compose this into our reducer using the `@ComposeBodyActionCase` directive. 

```diff
 @Composer
 struct Counter {
   struct State {
     var count = 0
   }

-  enum Action {
+  enum ViewAction {
     case decrementButtonTapped
     case incrementButtonTapped
   }
 }

-  var body: some ReducerOf<Self> {
-    Reduce { action, state in
+  @ComposeBodyActionCase
+  func view(state: inout State, action: ViewAction) {
     switch action {
       case .decrementButtonTapped:
        state.count -= 1
-        return .none
      case .incrementButtonTapped:
        state.count += 1
-        return .none
   }
```

<details>
<summary>

#### Let's see what code was generated. Click to expand the `@Composer` macro

</summary>
    
```diff
 @Composer
 
 struct Counter {
+  @ObservableState 
   struct State {
     var count = 0
   }

+  @CasePathable
   enum ViewAction {
     case decrementButtonTapped
     case incrementButtonTapped
   }

   @ComposeBodyActionCase
   func view(state: inout State, action: ViewAction) {
     switch action {
       case .decrementButtonTapped:
        state.count -= 1
      case .incrementButtonTapped:
        state.count += 1
   }
+
+  @CasePathable
+  enum Action: ComposableArchitecture.ViewAction {
+    view(ViewAction)
+  }
+
+  @ReducerBuilder<State, Action>
+  var body: some ReducerOf<Self> {
+    TCAComposer.ReduceAction(\.view) { state, action in
+      self.view(state: &state, action: action)
+      return .none
+    }
+  }
}
```

Composer has now automatically generated a functional `body` and added a `view` case to `Action` with the associated type of `ViewAction`. This all came about due to the magic of `@ComposeBodyActionCase` directive. It serves two purposes:

* Composer adds a case member to `Action` based upon the function's signature.
  * The function's name, in this case `view`, will be used for the case name.
  * You can override the case name, by passing a parameter to the macro. For example: `@ComposeBodyActionCase("myCustomCaseName")`
  * The type of the `action` parameter will be used for the type of case's associated value.
* Composer invokes your function from the `body` by destructuring `Action` using the case name.
  * Composer allows you flexibility in how you declare your function signature. You are to free to omit the `state` parameter or the return type of `Effect`. Composer will automatically adjust how it invokes your reduce function based upon the signature. In this example, the return type was omitted and Composer automatically adapted to always return the `.none` effect after calling the `view` function.
  
</details>

### Composing Reducers

The real power of Composer comes from composing child reducers into a parent reducer. Let's create a `TwoCounters` reducer that consists of two `Counter` reducers. To accomplish this we are going to use a `@ComposeReducer` macro attached to our top level reducer declaration. This maros allows you to declare all of your child reducers in one place, including reducers for navigation destinations and navigation stacks. It also allows for some additional customization such as conforming `Action` to `BindableAction`  to allow bindable access to `State` from a `View`. In the example below, the `.bindable` option is specified to `@ComposeReducer` to enable bindings and two children named `counter1` and `counter2` are added.

```swift
 @ComposeReducer(
   .bindable,
   children: [
     .reducer("counter1", of: Counter.self, initialState: .init()),
     .reducer("counter2", of: Counter.self, initialState: .init())
   ]
 )
 @Composer
 struct TwoCounters {
   
   struct State {
     var isDisplayingSum = false
   }
   enum ViewAction {
     case resetCountersTapped
   }
   
   @ComposeBodyActionCase
   func view(state: inout State, action: ViewAction) {
     switch action {
     case .resetCountersTapped:
       state.counter1.count = 0
       state.counter2.count = 0
     }
   }
 }
```

<details>
<summary>

#### Let's see what code was generated. Click to expand the `@Composer` macro

</summary>
    
```diff
@ComposeReducer(
  .bindable,
  children: [
    .reducer("counter1", of: Counter.self, initialState: .init()),
    .reducer("counter2", of: Counter.self, initialState: .init())
  ]
)
@Composer
struct TwoCounters {
  
+ @_ComposerScopePathable
+ @_ComposedStateMember("counter1", of: Counter.State.self, initialValue: .init())
+ @_ComposedStateMember("counter2", of: Counter.State.self, initialValue: .init())
+ @ObservableState
  struct State {
    var isDisplayingSum = false
  }
  
+ @CasePathable
  enum ViewAction {
    case resetCountersTapped
  }
  
  @ComposeBodyActionCase
  func view(state: inout State, action: ViewAction) {
    switch action {
    case .resetCountersTapped:
      state.counter1.count = 0
      state.counter2.count = 0
    }
  }
  
+ @CasePathable
+ enum Action: ComposableArchitecture.BindableAction, ComposableArchitecture.ViewAction {
+   case binding(BindingAction<State>)
+   case counter1(Counter.Action)
+   case counter2(Counter.Action)
+   case view(ViewAction)
+ }
+
+ @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
+ var body: some ReducerOf<Self> {
+   ComposableArchitecture.BindingReducer()
+   ComposableArchitecture.Scope(state: \.counter1, action: \Action.Cases.counter1) {
+     Counter()
+   }
+   ComposableArchitecture.Scope(state: \.counter2, action: \Action.Cases.counter2) {
+     Counter()
+   }
+   ComposableArchitecture.CombineReducers {
+     TCAComposer.ReduceAction(\Action.Cases.view) { state, action in
+       self.view(state: &state, action: action)
+         return .none
+     }
+   }
+ }
+
+ struct AllComposedScopePaths {
+   var counter1: TCAComposer.ScopePath<TwoCounters.State, Counter.State, TwoCounters.Action, Counter.Action> {
+     get {
+       return TCAComposer.ScopePath(state: \State.counter1, action: \Action.Cases.counter1)
+     }
+   }
+   var counter2: TCAComposer.ScopePath<TwoCounters.State, Counter.State, TwoCounters.Action, Counter.Action> {
+     get {
+       return TCAComposer.ScopePath(state: \State.counter2, action: \Action.Cases.counter2)
+     }
+   }
+ }
}
```

Wow, that's a lot code! Composer has automatically generated an `Action` that includes conformance for `BindingAction` thanks to the `.bindable` option. The `Action` also incorporates cases for our two reducer children and the `view` action from `@ComposeBodyActionCase` macro. The automatically generated `body` calls the `BindingReducer`, scopes the two child reducers and then finally invokes our `view` function to reduce the `ViewAction`.

You will also notice that new macros appear that begin with an underscore are attached to `State`. These are internal macros that Composer uses to generate code in portions of your `Reducer` code and are a byproduct of how the swift macro system works. The internal macros are not meant to be used by you and may change from release to release. Here's what they look like when fully expanded for `State`:

```diff
 @ObservableState
 struct State {
   var isDisplayingSum = false
    
+  static var allComposedScopePaths: AllComposedScopePaths {
+    AllComposedScopePaths()
+  }
+ 
+  @ObservationStateTracked
+  var counter1: Counter.State = .init()
+  @ObservationStateIgnored
+  private var _counter1: Counter.State
+ 
+  @ObservationStateTracked
+  var counter2: Counter.State = .init()
+  @ObservationStateIgnored
+  private var _counter2: Counter.State
 }
```

The macros automatically added new members to `State` for our child reducers including the required support for `@ObservableState`. The `@_ComposerScopePathable` macro combined with the generated `AllComposedScopePaths` struct provides support for improving [view ergonomics](#improved-view-ergonomics) by generating a `ScopePath` for each child reducer so that you can scope a child reducer using `store.scopes.counter1`, rather than the more verbose `store.scope(state: \.counter1, action: \.counter1)`. Pretty cool, eh?

</details>

### More to come....

More examples of using Composer coming over the next few days. In the meantime, checkout the [Examples](#examples) for more complex usage.

## Improved View Ergonomics

### ScopePaths

Composer introduces a new concept of a `ScopePath` that simplify the creation of scopes in TCA applications. `ScopePath`s are created automatically by Composer and are a more concise way to scope stores in your application using a single `KeyPath` to a `ScopedPath` rather than separate state and action `KeyPaths`. For example it is now possible to write code like this:

```diff
- ChildView(store: store.scope(state: \.child, action: \.child))
+ ChildView(store: store.scopes.child)

- ForEach(store.scope(state: \.children, action: \.children)) {
+ ForEach(store.scopes.children) {
  }

- .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
+ .alert($store.scopes(\.destination.alert))
```

## Documentation

The documentation for releases and `main` are available here:

* [`main`](https://swiftpackageindex.com/mentalflux/tca-composer/main/documentation/tcacomposer)
* [0.1.0](https://swiftpackageindex.com/mentalflux/tca-composer/0.1.0/documentation/tcacomposer)
  
## Known Issues

### Xcode Macro Expansion

Xcode does not currently expand macros in the source editor when there are multiple macros on the same source line. This is a common occurence when Composer adds members to existing `State` and `Action` declarations, and will prevent you from seeing the code that is being generated. However, if the generated code produces a compiler error, Xcode will expand the macros and show you the error.

### Swift Compiler

A number of bugs in the swift compiler were discovered while developing Composer. Many of these were mitigated by changes in Composer's design and implementation. However, some compiler issues may still be encountered when using Composer (though in experience most can be worked around). If you encounter a troublesome compiler error, please file an issue or start a discussion.

## Credits

Special thanks to Brandon Williams and Stephen Celis for the amazing work they do at [Point-Free](https://www.pointfree.co) including [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture), [CasePaths](https://github.com/pointfreeco/swift-case-paths), and [Swift Macro Testing](https://github.com/pointfreeco/swift-macro-testing) projects, which made this project possible.

## License

This library is relased under the MIT license. See [LICENSE](LICENSE) for details.

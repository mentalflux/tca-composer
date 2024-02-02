# TCA Composer

TCA Composer is a swift macro framework for eliminating boiler-plate code in [TCA-based](https://github.com/pointfreeco/swift-composable-architecture) applications. Composer provides a collection of swift macros that allow you to declaritively construct a `Reducer` and automaticaly generate all or portions of the `State`, `Action`, and `body` declarations. Composer can also automatically generate an entire `Reducer` for use in navigation destinations and stacks. Composer encourages simple design patterns to structure your code, while still allowing you complete flexibility in how to structure your code and application.

> [!Important]
> Composer requires version 1.7.0 (or later) of The Composable Architecture. Composer also requires the adoption of `ObservableState` in your `Reducer`.
> If you are migrating an existing `Reducer` to Composer, it is highly recommended that you first update your `Reducer` to use `ObservableState` by following the [migration guide](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/migratingto1.7) to make a transition to 
> using Composer much smoother.

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

-  var body:
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
+  enum Action: ViewAction {
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

### More to come soon...

More examples of using Composer over the next few days...

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

## Known Issues

### XCode Macro Expansion

XCode does not currently expand macros in the source editor when there are multiple macros on the same source line. This is a common occurence when Composer adds members to existing `State` and `Action` declarations, and will prevent you from seeing the code that is being generated. However, if the generated code produces a compiler error, Xcode will expand the macros and show you the error.

### Swift Compiler

A number of bugs in the swift compiler were discovered while developing Composer. Many of these were mitigated by changes in Composer's design and implementaiton. However, some compiler issues may still be experienced when using Composer.

## Credits

Special thanks to Brandon Williams and Stephen Celis for the amazing work they do at [Point-Free](https://www.pointfree.co) including [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture), [CasePaths](https://github.com/pointfreeco/swift-case-paths), and [Swift Macro Testing](https://github.com/pointfreeco/swift-macro-testing) projects, which made this project possible.

## License

This library is relased under the MIT license. See [LICENSE](LICENSE) for details.

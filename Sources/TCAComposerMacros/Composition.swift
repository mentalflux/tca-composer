import CasePaths
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import IssueReporting
import OrderedCollections

class Composition {
  var options = Set<Option>()

  let accessModifier: String
  var stateDecl: DeclSyntax?

  var bodyDecl: VariableDeclSyntax?
  let reducerDecl: StructDeclSyntax
  let context: MacroExpansionContext

  var actionMembers = [ActionMember]()
  var stateMembers = [StateMember]()

  var scopes = [ScopePath]()
  var unresolvedScopes = [ScopePath]()
  var scopeCases = [ScopeCase]()

  var bodyBeforeCoreMembers = [BodyMember]()
  var bodyCoreMembers = [BodyMember]()
  var bodyCoreModifiers = [BodyMember]()
  var bodyAfterCoreMembers = [BodyMember]()
  var bindingReducer: BodyMember?

  // Reducers that need to be be converted to BodyMembers
  // after @ComposeBodyReducerChild macros have been processed
  var childReducers = OrderedDictionary<String, ScopedChildReducer>()
  var childBodyReducers = [ScopedChildReducer]()

  // Preserve a reference to the source of the child delcartaion for diagnostics.
  var childSourceDeclarations = [String: SyntaxProtocol]()

  var hasBeenAnalyzed = false

  var placeholders = TypePlaceholders()

  let reducerContext: ReducerContext

  var hasReducerInitializer: Bool = false
  var hasStateInitializer: Bool = false

  var enumeratedStateInitialValueMember: StateMember?

  let isStateEnum: Bool

  var stateConformanceOptions = Set<ConformanceOptions>()
  var actionConformanceOptions = Set<ConformanceOptions>()

  var isMissingStateDeclaration: Bool {
    stateDecl == nil
  }

  var isMissingBodyDeclaration: Bool {
    bodyDecl == nil
  }

  var hasViewAction: Bool {
    // TODO: need to handle existing Action case.
    return actionMembers.contains(where: { $0.name == "view" })
  }

  var hasNavigationReducers: Bool {
    scopes.contains(where: { $0.type.is(\.navigationDestination) || $0.type.is(\.navigationStack) })
  }

  var isBindable: Bool {
    options.contains(.bindable)
  }

  var isNested: Bool {
    return !reducerContext.is(\.root)
  }

  var needsScopePaths: Bool {
    !scopes.isEmpty && !reducerContext.is(\.navigationPath)
  }

  var needsScopeCases: Bool {
    reducerContext.is(\.navigationPath) || (reducerContext.is(\.root) && isStateEnum)
  }

  var requiresBodyCore: Bool {
    !bodyCoreMembers.isEmpty || !bodyCoreModifiers.isEmpty || !childBodyReducers.isEmpty
  }

  var confromancesForAction: [String] {
    var conformances = actionConformanceOptions.compactMap({ $0.conformanceType })

    if isNested {
      conformances.append("CasePaths.CasePathable")
    }

    if isBindable {
      conformances.append("ComposableArchitecture.BindableAction")
    }

    if hasViewAction {
      conformances.append("ComposableArchitecture.ViewAction")
    }

    return conformances.sorted()
  }

  var confromancesForState: [String] {
    var conformances = stateConformanceOptions.compactMap({ $0.conformanceType })

    if !stateConformanceOptions.contains(.notEquatable) {
      conformances.append("Equatable")
    }

    if isStateEnum {
      // NB: We must explicilty conform to CasePathable and ObservableState to avoid linking issues
      //     for protocol witness tables which seem to go missing with macro expansion when nested.
      if isNested {
        conformances.append("CasePaths.CasePathable")
        conformances.append("ComposableArchitecture.ObservableState")
        if needsScopeCases {
          conformances.append("TCAComposer.ScopeSwitchable")
        }
      }
    } else {
      if needsScopePaths {
        conformances.append("TCAComposer.ScopePathable")
      }
    }

    return conformances.sorted()
  }

  enum Option: String {
    case bindable
  }

  enum ConformanceOptions: String {
    case codable
    case equatable
    case hashable
    case notEquatable
    case sendable

    var conformanceType: String? {
      switch self {
      case .codable:
        "Codable"
      case .equatable:
        "Equatable"
      case .hashable:
        "Hashable"
      case .notEquatable:
        nil
      case .sendable:
        "Sendable"
      }
    }
  }

  init(reducerDecl: StructDeclSyntax, context: MacroExpansionContext) {
    self.reducerDecl = reducerDecl
    self.context = context
    self.reducerContext = .root
    self.isStateEnum = false
    self.accessModifier =
      reducerDecl.modifiers.first(where: \.isNeededAccessLevelModifier)?.trimmedDescription
      .appending(" ") ?? ""
  }

  init(
    reducerDecl: StructDeclSyntax, context: MacroExpansionContext, attribute: AttributeSyntax,
    placeholders: TypePlaceholders = .init(), reducerContext: ReducerContext = .root
  ) {
    self.reducerDecl = reducerDecl
    self.context = context
    self.placeholders = placeholders
    self.reducerContext = reducerContext
    self.accessModifier =
      reducerDecl.modifiers.first(where: \.isNeededAccessLevelModifier)?.trimmedDescription
      .appending(" ") ?? ""
    if attribute.attributeName.trimmedDescription == MacroNames.composeEnumReducer {
      isStateEnum = true
    } else {
      isStateEnum = false
    }

    guard
      case let .argumentList(argumentList) = attribute.arguments
    else {
      return
    }

    var initialStateCaseExpr: StringLiteralExprSyntax?

    for argument in argumentList {
      guard let label = argument.label?.text else {
        // unlabeled arguments are options, process them.
        if let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
          let option = Option(rawValue: memberAccessExpr.declName.trimmedDescription)
        {
          options.insert(option)
        } else if let functionCallExpr = argument.expression.as(FunctionCallExprSyntax.self),
          let memberAccessExpr = functionCallExpr.calledExpression.as(MemberAccessExprSyntax.self)
        {

          switch memberAccessExpr.declName.baseName.text {
          case "action":
            for argument in functionCallExpr.arguments {
              guard let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
                let option = ConformanceOptions(
                  rawValue: memberAccessExpr.declName.trimmedDescription)
              else {
                reportIssue("Unknown option in .state options")
                continue
              }
              actionConformanceOptions.insert(option)
            }

          case "initialStateCase":
            guard let argument = functionCallExpr.arguments.first,
              let expression = argument.expression.as(StringLiteralExprSyntax.self)
            else {
              context.diagnose(
                Diagnostic(
                  node: argument,
                  message: MacroExpansionErrorMessage(
                    """
                    Only string literals may be used when specifying an `initialStateCase`
                    """
                  )
                )
              )
              continue
            }
            initialStateCaseExpr = expression

          case "state":
            for argument in functionCallExpr.arguments {
              guard let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
                let option = ConformanceOptions(
                  rawValue: memberAccessExpr.declName.trimmedDescription)
              else {
                reportIssue("Unknown option in .state options")
                continue
              }
              stateConformanceOptions.insert(option)
            }

          default:
            reportIssue("Unknown argument in @ComposeReducer options")
          }
        }
        continue
      }

      if label == "children" {
        guard let arrayExpr = argument.expression.as(ArrayExprSyntax.self) else {
          return
        }

        for element in arrayExpr.elements {
          guard let expression = element.expression.as(FunctionCallExprSyntax.self) else {
            // TODO: internal Diagnostics
            continue
          }
          processRootChild(expr: expression)
        }
      }
    }

    if isBindable {
        bindingReducer = .init(name: Identifiers.BindingReducer)
    }
    
    if let initialStateCaseExpr {
      let caseName = initialStateCaseExpr.segments.trimmedDescription
      guard let stateMember = stateMembers.first(where: { $0.name == caseName }) else {
        context.diagnose(
          Diagnostic(
            node: initialStateCaseExpr,
            message: MacroExpansionErrorMessage(
              """
              '\(caseName)' is not a valid initialStateCase name.
              """
            )
          )
        )
        return
      }
      guard stateMember.initialValue != nil || stateMember.type == "Void" else {
        context.diagnose(
          Diagnostic(
            node: initialStateCaseExpr,
            message: MacroExpansionErrorMessage(
              """
              '\(caseName)' does not have a default value and cannot be used for an `initialStateCase`.
              "Add an initialValue to `'\(caseName)' to resolve.
              """
            )
          )
        )
        return
      }
      enumeratedStateInitialValueMember = stateMember
    }
  }

  func analyze() {
    guard !hasBeenAnalyzed else {
      return
    }
    defer { hasBeenAnalyzed = true }

    let analyzer = ReducerAnalyzer(composition: self)
    analyzer.analyze(reducerDecl)

    // Add scopes if not enum
    if !isStateEnum || bodyCoreMembers.isEmpty {
      bodyBeforeCoreMembers.insert(contentsOf: childReducers.values.map { $0.reducerBuilderMember }, at: 0)
    }
    else {
      bodyCoreModifiers.insert(contentsOf: childReducers.values.map { $0.coreBodyModifier }, at: 0)
    }

    if let bindingReducer {
      actionMembers.append(.init(name: "binding", type: "BindingAction<State>"))
      bodyBeforeCoreMembers.insert(bindingReducer, at: 0)
      // TODO: handle conformance and attributes for Action here
    }

    bodyCoreModifiers.insert(contentsOf: childBodyReducers.map { $0.coreBodyModifier }, at: 0)

    // Add alert and confirmaiton dialog members
    for (name, placeholder) in placeholders.placeholders {
      if name.contains(".") {
        continue
      }
      addMembers(name: name, childType: placeholder.type, sourceSyntax: placeholder.sourceSyntax)
    }

    // Resolve scopePaths to actions
    for unresolvedScope in unresolvedScopes {
      let actionName = unresolvedScope.keyPaths.action.deletingPrefix("\\Action.Cases.")
      guard !actionName.contains(".") else {
        continue
      }
      guard let actionType = actionMembers.first(where: { $0.name == actionName })?.type else {
        // TODO: diagnostic, need a handle to the original macro.
        continue
      }
      scopes.append(unresolvedScope.resolveActionType(actionType))
    }
  }

  @discardableResult
  func addAction(name: String, type: String, sourceSyntax: SyntaxProtocol) -> Bool {
    if let existingDecl = childSourceDeclarations[name] {
      context.diagnose(
        Diagnostic(
          node: sourceSyntax,
          message: MacroExpansionErrorMessage(
            """
            Duplicate definition of an action named '\(name)'.
            """
          ),
          notes: [
            Note(
              node: Syntax(existingDecl),
              message: MacroExpansionNoteMessage("'\(name)' already defined here.")
            )
          ]
        )
      )
      return false
    }

    actionMembers.append(.init(name: name, type: type))
    return true
  }

  func addMembers(
    name: String, childType: ChildType, initialValue: String? = nil, sourceSyntax: SyntaxProtocol
  ) {
    if let existingDecl = childSourceDeclarations[name] {
      context.diagnose(
        Diagnostic(
          node: sourceSyntax,
          message: MacroExpansionErrorMessage(
            """
            Duplicate definition of a child named '\(name)'.
            """
          ),
          notes: [
            Note(
              node: Syntax(existingDecl),
              message: MacroExpansionNoteMessage("'\(name)' already defined here.")
            )
          ]
        )
      )
      return
    }

    // Only add child for diagnostics if we are in the root reducer.
    if reducerContext.is(\.root) {
      childSourceDeclarations[name] = sourceSyntax
    }

    // Do not process scoped child here.
    guard !name.contains(".") else {
      return
    }

    if let stateType = childType.stateTypeName {
      stateMembers.append(
        .init(
          name: name, type: stateType, initialValue: initialValue, presents: childType.isPresentable
        ))
    }

    if let actionType = childType.actionTypeName {
      actionMembers.append(.init(name: name, type: actionType))
    }

    if isStateEnum {
      let stateKeyPath = "\\State.\(name)"
      let actionKeyPath = "\\Action.Cases.\(name)"
      scopeCases.append(
        .init(
          name: name,
          type: childType,
          keyPaths: .init(action: actionKeyPath, state: stateKeyPath)))
    }

    if let stateType = childType.stateTypeName, let actionType = childType.actionTypeName {
      var actionKeyPath = "\\Action.Cases.\(name)"
      var adjustedActionType = actionType
      // TODO: clean this up
      if childType.isPresentable, !stateType.hasPrefix("AlertState<"),
        !stateType.hasPrefix("ConfirmationDialogState<")
      {
        actionKeyPath += ".presented"
        adjustedActionType = String(actionType.dropFirst("PresentationAction<".count).dropLast())
      }
      let adjustedStateType = isStateEnum ? "\(stateType)?" : stateType
      var stateKeyPath = isStateEnum ? "\\State.[dynamicMember: \\.\(name)]" : "\\State.\(name)"

      if case let .navigationDestination(destinationName, parentType) = reducerContext {
        stateKeyPath = "\\\(parentType).State.\(destinationName)?.\(name)"
        actionKeyPath = "\\\(parentType).Action.Cases.\(destinationName).\(name)"
        adjustedActionType = "PresentationAction<\(actionType)>"
      }

      scopes.append(
        .init(
          name: name,
          type: childType,
          keyPaths: .init(action: actionKeyPath, state: stateKeyPath),
          adjustedStateType: adjustedStateType,
          adjustedActionType: adjustedActionType))
    }
  }

  func processRootChild(expr: FunctionCallExprSyntax) {
    guard
      let methodName = expr.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    else {
      return
    }

    switch methodName {
    case "presentsDestination":
      processNavigationDestination(expr: expr)
    case "navigationStack":
      processNavigationPath(expr: expr)
    default:
      processChild(expr: expr)
    }
  }

  func processNavigationDestination(expr: FunctionCallExprSyntax) {
    var name = "destination"
    var reducerName = "Destination"
    var childrenSyntax: LabeledExprSyntax?

    for argument in expr.arguments {
      guard let label = argument.label?.trimmedDescription else {
        name =
          argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription
          ?? "destination"
        continue
      }
      if label == "reducerName" {
        reducerName =
          argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription
          ?? "Destination"
      } else if label == "children" {
        childrenSyntax = argument
        guard let arrayExpr = argument.expression.as(ArrayExprSyntax.self) else {
          continue
        }
        for element in arrayExpr.elements {
          guard let childExpr = element.expression.as(FunctionCallExprSyntax.self) else {
            continue
          }
          processChild(expr: childExpr, scopeName: name)
        }
      }
    }

    childBodyReducers.append(
      ScopedChildReducer(name: name, functionName: Identifiers.ifLet, useBinding: true) {
        [weak self] in
        self?.reducer(for: name)
      })

    addMembers(
      name: name, childType: .navigationDestination(reducerName, childrenSyntax: childrenSyntax),
      sourceSyntax: expr)
  }

  func processNavigationPath(expr: FunctionCallExprSyntax) {
    var name = "path"
    var reducerName = "Path"
    var childrenSyntax: LabeledExprSyntax?

    for argument in expr.arguments {
      guard let label = argument.label?.trimmedDescription else {
        name =
          argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription
          ?? "path"
        continue
      }
      if label == "reducerName" {
        reducerName =
          argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription
          ?? "Path"
      } else if label == "children" {
        childrenSyntax = argument
        guard let arrayExpr = argument.expression.as(ArrayExprSyntax.self) else {
          continue
        }
        for element in arrayExpr.elements {
          guard let childExpr = element.expression.as(FunctionCallExprSyntax.self) else {
            continue
          }
          processChild(expr: childExpr, scopeName: name)
        }
      }
    }

    childBodyReducers.append(
      ScopedChildReducer(name: name, functionName: Identifiers.forEach) { [weak self] in
        self?.reducer(for: name)
      })

    addMembers(
      name: name, childType: .navigationStack(reducerName, childrenSyntax: childrenSyntax),
      initialValue: ".init()", sourceSyntax: expr)
  }

  func processChild(expr: FunctionCallExprSyntax, scopeName: String? = nil) {
    var name = ""
    var type = ""
    var initialValue: String?
    var tupleExpr: TupleExprSyntax?
    var nameExpr: ExprSyntax?
    var methodName = expr.calledExpression.cast(MemberAccessExprSyntax.self).declName.baseName.text
    var presents: Bool = false

    for argument in expr.arguments {
      switch argument.label?.text {
      case "of":
        guard let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
          let baseType = memberAccessExpr.base,
          memberAccessExpr.declName.baseName.text == "self"
        else {
          continue
        }
        type = baseType.trimmedDescription
        tupleExpr = baseType.as(TupleExprSyntax.self)

      case "initialState",
        "initialValue":
        initialValue = argument.expression.trimmedDescription

      case nil:
        name =
          argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription ?? ""
        nameExpr = argument.expression

      default:
        // TODO: internal diagnostic
        return
      }
    }

    if methodName.hasPrefix("presents") {
      methodName = methodName.deletingPrefix("presents").lowerFirst()
      presents = true
    }

    if name.isEmpty {
      switch methodName {
      case "alert",
        "confirmationDialog":
        name = methodName
      default:
        context.diagnose(
          Diagnostic(
            node: expr,
            message: MacroExpansionErrorMessage(
              """
              Invalid or missing name.
              """
            )
          )
        )
        return
      }
    }

    if type.isEmpty {
      switch methodName {
      case "alert",
        "confirmationDialog":
        type = "Never"
      case "stateless":
        type = "Void"
      default:
        context.diagnose(
          Diagnostic(
            node: expr,
            message: MacroExpansionErrorMessage(
              """
              Invalid or missing type.
              """
            )
          )
        )
      }
    }

    if let scopeName {
      name = "\(scopeName).\(name)"
    }

    switch methodName {
    case "alert":
      placeholders[name] = .init(
        type: .alert(type, presentable: presents), sourceSyntax: nameExpr ?? expr)

      if presents && scopeName == nil {
        childBodyReducers.append(
          ScopedChildReducer(name: name, functionName: Identifiers.ifLet, useBinding: true))
      }

    case "confirmationDialog":
      placeholders[name] = .init(
        type: .confirmationDialog(type, presentable: presents), sourceSyntax: nameExpr ?? expr)

      if presents && scopeName == nil {
        childBodyReducers.append(
          ScopedChildReducer(name: name, functionName: Identifiers.ifLet, useBinding: true))
      }

    case "identifiedArray":
      addMembers(
        name: name, childType: .identifiedArray(type), initialValue: initialValue,
        sourceSyntax: expr)
      childBodyReducers.append(
        ScopedChildReducer(name: name, functionName: Identifiers.forEach) { [weak self] in
          self?.reducer(for: name)
        })

    case "reducer":
      // TODO: Tidy up the optional checking when combined with presents.
      let childType: ChildType =
        if type.hasSuffix("?") {
          .reducer(type.deletingSuffix("?"), optional: true)
        } else {
          .reducer(type, presentable: presents)

        }
      addMembers(
        name: name, childType: childType, initialValue: initialValue, sourceSyntax: nameExpr ?? expr
      )

      // Do not add childBodyReducers if we are scoped.
      guard scopeName == nil else {
        return
      }

      if type.hasSuffix("?") || presents {
        childBodyReducers.append(
          ScopedChildReducer(name: name, functionName: Identifiers.ifLet, useBinding: presents) {
            [weak self] in
            self?.reducer(for: name)
          })
      } else {
        childReducers[name] =
          ScopedChildReducer(name: name) { [weak self] in
            self?.reducer(for: name)
          }
      }

    case "state":
      let childType: ChildType =
        if let tupleExpr {
          .tupleState(tupleExpr)
        } else {
          .state(type)
        }

      if childType.is(\.tupleState), initialValue != nil {
        context.diagnose(
          Diagnostic(
            node: expr,
            message: MacroExpansionWarningMessage(
              """
              initialValue not supported with tuple state. Value will be ignored.
              """
            )
          )
        )
      }

      addMembers(name: name, childType: childType, initialValue: initialValue, sourceSyntax: expr)

    case "stateless":
      addMembers(name: name, childType: .stateless, initialValue: initialValue, sourceSyntax: expr)

    default:
      reportIssue(
        "@Composer found an unknown child type named \"\(methodName)\" while process @ComposeReducer"
      )
    }
  }

  func reducer(for name: String) -> FunctionCallExprSyntax? {
    guard let reducerType = scopes.first(where: { $0.name == name })?.type.reducerType else {
      return nil
    }
    return FunctionCallExprSyntax(
      callee: DeclReferenceExprSyntax(
        baseName: .identifier(reducerType)
      )
    )
  }
}

struct MacroExpansionNoteMessage: NoteMessage {
  var message: String

  init(_ message: String) {
    self.message = message
  }

  var fixItID: MessageID {
    MessageID(domain: "SwiftSyntaxMacroExpansion", id: "\(Self.self)")
  }
  
  var noteID: MessageID {
    MessageID(domain: "SwiftSyntaxMacroExpansion", id: "\(Self.self)")
  }
}

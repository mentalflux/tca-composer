import CasePaths
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import XCTestDynamicOverlay

final class ReducerAnalyzer: SyntaxVisitor {
  var composition: Composition

  init(composition: Composition) {
    self.composition = composition
    super.init(viewMode: .all)
  }

  func analyze(_ reducerDecl: StructDeclSyntax) {
    self.walk(reducerDecl.memberBlock)
  }

  var vistingActionEnum: EnumDeclSyntax?
  var visitingState: Bool = false
  // TODO: rename this, it can be confusing
  var scopeNames = [String]()

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if vistingActionEnum != nil,
      node.name.text == "AllCasePaths"
    {
      composition.actionHasAllCasePaths = true
    } else if scopeNames.isEmpty,
      node.name.text == "State"
    {
      composition.stateDecl = node.cast(DeclSyntax.self)
      scopeNames.append(node.name.text)
      visitingState = true
      // TODO: Visit children and gather member names for diagnostics
      return .visitChildren
    }
    return .skipChildren
  }

  override func visitPost(_ node: StructDeclSyntax) {
    // NB: This is always called even if we skipped children, should be ok for now, but if above logic changes, may need to adjust
    _ = scopeNames.popLast()
    if visitingState {
      visitingState = false
    }
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.name.trimmedDescription == "Action" {
      composition.actionDecl = node
      vistingActionEnum = node
      
      // TODO: Visit children to get member names for diagnostics
    }
    if node.name.trimmedDescription == "State" {
      composition.stateDecl = node.cast(DeclSyntax.self)
      visitingState = true
      // TODO: Visit children and gather member names for diagnostics
    }
    if let attribute = node.attributes.firstAttribute(for: MacroNames.composeActionCase) {
      processActionCase(node, attribute: attribute)
    } else if let attribute = node.attributes.firstAttribute(for: MacroNames.composeActionAlertCase)
    {
      processPlaceholder(type: node.name.text, attribute: attribute, casePath: \.alert)
    } else if let attribute = node.attributes.firstAttribute(
      for: MacroNames.composeActionConfirmationDialogCase)
    {
      processPlaceholder(type: node.name.text, attribute: attribute, casePath: \.confirmationDialog)
    }

    scopeNames.append(node.name.text)
    return .visitChildren
  }

  override func visitPost(_ node: EnumDeclSyntax) {
    _ = scopeNames.popLast()
    if visitingState {
      visitingState = false
    }
    if vistingActionEnum == node {
      vistingActionEnum = nil
    }
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.bindingSpecifier.text == "var",
      node.bindings.count == 1,
      let binding = node.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
      identifier.text == "body"
    {
      composition.bodyDecl = node
    }

    // TODO: gather members if visting State for diagnostics

    // TODO: Clean up how we process this.
    if let attribute = node.attributes.firstAttribute(for: MacroNames.composeScopePath) {
      processScopePath(node, attribute: attribute)
    }

    return .skipChildren
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard node.attributes.count > 0 else {
      return .skipChildren
    }

    // TODO: need code to check for the prescence of multiple conflicting and/or redundant attributes
    if let attribute = node.attributes.firstAttribute(for: MacroNames.composeBodyActionCase) {
      processBodyNestedAction(node, attribute: attribute)
    } else if let attribute = node.attributes.firstAttribute(for: MacroNames.composeBody) {
      processBody(node, attribute: attribute)
    } else if let attribute = node.attributes.firstAttribute(for: MacroNames.composeBodyOnChange) {
      processBodyOnChange(node, attribute: attribute)
    } else if let attribute = node.attributes.firstAttribute(
      for: MacroNames.composeBodyActionAlertCase)
    {
      processBodyActionPlaceholder(node, attribute: attribute, casePath: \.alert)
    } else if let attribute = node.attributes.firstAttribute(
      for: MacroNames.composeBodyActionConfirmationDialogCase)
    {
      processBodyActionPlaceholder(node, attribute: attribute, casePath: \.confirmationDialog)
    }

    return .skipChildren
  }

  override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
    if scopeNames.isEmpty {
      composition.hasReducerInitializer = true
    } else if scopeNames == ["State"] {
      composition.hasStateInitializer = true
    }
    return .skipChildren
  }

  func analayzeSignature(
    _ node: FunctionDeclSyntax, attribute: AttributeSyntax, allowedParameters: [String]
  ) -> ReduceMethodSignature? {
    var parameters = [ReduceMethodSignature.Parameter]()

    for parameter in node.signature.parameterClause.parameters {
      let name = parameter.firstName.text
      switch name {
      case "state",
        "action",
        "id",
        "newValue",
        "oldValue":
        let isInOut = parameter.type.as(AttributedTypeSyntax.self)?.specifier?.text == "inout"

        if isInOut, name != "state" {
          composition.context.diagnose(
            Diagnostic(
              node: parameter.firstName,
              message: MacroExpansionErrorMessage(
                """
                @\(attribute.attributeName.trimmedDescription) doesn't allow inout parameter named "\(name)" in function signature.
                """
              )
            )
          )
        }

        if allowedParameters.contains(where: { $0 == name }) {
          parameters.append(
            .init(name: name, type: parameter.type.trimmedDescription, isInOut: isInOut))
        } else {
          let errorMessage =
            name == "id"
            ? MacroExpansionErrorMessage(
              """
              @\(attribute.attributeName.trimmedDescription) doesn't allow a parameter named "id" unless using identifiedAction.
              """
            )
            : MacroExpansionErrorMessage.nameNotAllowedInSignature(attribute: attribute, name: name)

          composition.context.diagnose(
            Diagnostic(
              node: parameter.firstName,
              message: errorMessage
            )
          )
        }

      default:
        composition.context.diagnose(
          Diagnostic(
            node: parameter.firstName,
            message: MacroExpansionErrorMessage.nameNotAllowedInSignature(
              attribute: attribute, name: name)
          )
        )
      }
    }

    var returnType: String?

    if let returns = node.signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
      returnType = returns.trimmedDescription
    }

    return ReduceMethodSignature(parameters: parameters, returnType: returnType)
  }

  func processBodyNestedAction(_ node: FunctionDeclSyntax, attribute: AttributeSyntax) {
    guard
      let signature = analayzeSignature(
        node, attribute: attribute, allowedParameters: ["state", "action"])
    else {
      return
    }

    guard let actionType = signature.actionType else {
      composition.context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroExpansionErrorMessage(
            """
            @\(MacroNames.composeBodyActionCase) requires an action parameter to infer an Action type.
            """
          )
        )
      )
      return
    }

    var name = node.name.text

    if case let .argumentList(argumentList) = attribute.arguments {
      for argument in argumentList {
        if argument.label == nil {
          // TODO: Diagnostics for non string literal expression or not identifier.
          name =
            argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription ?? ""
        }
      }
    }

    if composition.addAction(name: name, type: actionType, sourceSyntax: attribute) {
      processBody(
        node,
        attribute: attribute,
        signature: signature,
        actionKeyPath: "\\Action.Cases.\(name)")
    }

  }

  func processBodyActionPlaceholder(
    _ node: FunctionDeclSyntax,
    attribute: AttributeSyntax,
    casePath: PartialCaseKeyPath<ChildType>
  ) {
    guard
      let signature = analayzeSignature(
        node, attribute: attribute, allowedParameters: ["state", "action"])
    else {
      return
    }

    guard let actionType = signature.actionType else {
      composition.context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroExpansionErrorMessage(
            """
            @\(attribute.attributeName.trimmedDescription) requires an action parameter to infer an action type.
            """
          )
        )
      )
      return
    }

    guard
      let resolvedName = processPlaceholder(
        type: actionType,
        attribute: attribute,
        casePath: casePath)
    else {
      return
    }

    let actionKeyPath = "\\Action.Cases.\(resolvedName).presented"

    processBody(
      node,
      attribute: attribute,
      signature: signature,
      actionKeyPath: actionKeyPath)

  }

  func processBody(_ node: FunctionDeclSyntax, attribute: AttributeSyntax) {
    var actionKeyPath = ""
    var elementKeyPath = ""
    var allowedParameters = ["state", "action"]

    if case let .argumentList(argumentList) = attribute.arguments {
      for argument in argumentList {
        switch argument.label?.text {
        case "identifiedAction":
          allowedParameters.append("id")
          fallthrough

        case "action":
          actionKeyPath = argument.expression.trimmedDescription

        case "elementAction":
          elementKeyPath = argument.expression.trimmedDescription

        default:
          continue
        }
      }
    }

    guard
      let signature = analayzeSignature(
        node, attribute: attribute, allowedParameters: allowedParameters)
    else {
      return
    }

    processBody(
      node,
      attribute: attribute,
      signature: signature,
      actionKeyPath: actionKeyPath,
      elementKeyPath: elementKeyPath)
  }

  func processBody(
    _ node: FunctionDeclSyntax,
    attribute: AttributeSyntax,
    signature: ReduceMethodSignature,
    actionKeyPath: String = "",
    elementKeyPath: String = ""
  ) {
    var bodyPosition = BodyMember.Position.core

    if case let .argumentList(argumentList) = attribute.arguments {
      for argument in argumentList {
        switch argument.label?.text {
        case "position":
          if let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
            let option = BodyMember.Position(rawValue: memberAccessExpr.declName.trimmedDescription)
          {
            bodyPosition = option
          }
        default:
          continue
        }
      }
    }

    if !actionKeyPath.isEmpty {
      guard actionKeyPath.hasPrefix("\\Action.Cases.") else {
        composition.context.diagnose(
          Diagnostic(
            node: attribute,
            message: MacroExpansionErrorMessage(
              """
              Only CaseKeyPaths on Action are supported.  Keypath must begin with "\\Action.Cases"
              """
            )
          )
        )
        return
      }
    }

    let bodyMember = signature.bodyMember(
      name: node.name, actionKeyPath: actionKeyPath, elementKeyPath: elementKeyPath)

    switch bodyPosition {
    case .beforeCore:
      composition.bodyBeforeCoreMembers.append(bodyMember)
    case .core:
      composition.bodyCoreMembers.append(bodyMember)
    case .afterCore:
      composition.bodyAfterCoreMembers.append(bodyMember)
    }
  }

  func processBodyOnChange(_ node: FunctionDeclSyntax, attribute: AttributeSyntax) {
    guard case let .argumentList(argumentList) = attribute.arguments else {
      return
    }

    guard
      let signature = analayzeSignature(
        node, attribute: attribute, allowedParameters: ["state", "action", "oldValue", "newValue"])
    else {
      return
    }

    var stateKeyPath = ""
    var attachment: ComposeBodyOnChangeAttachment?
    
    for argument in argumentList {
      switch argument.label?.text {
      case "of":
        let keyPath = argument.expression.trimmedDescription
        guard keyPath.hasPrefix("\\State.") else {
          composition.context.diagnose(
            Diagnostic(
              node: argument.expression,
              message: MacroExpansionErrorMessage(
                """
                Keypath must begin with "\\State."
                """
              )
            )
          )
          return
        }
        stateKeyPath = "\\\(keyPath.dropFirst(6))"
      case "attachment":
        attachment = .init(argument.expression.trimmedDescription)
        switch attachment {
        case .binding:
          guard composition.bindingReducer != nil else {
            composition.context.diagnose(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage(
                """
                `.binding` attachment requires the Reducer have the `.bindable` option specified.
                """
                )
              )
            )
            return
          }
          
        case let .scope(name):
          guard composition.childReducers[name] != nil else {
            composition.context.diagnose(
              Diagnostic(
                node: argument.expression,
                message: MacroExpansionErrorMessage(
                """
                '\(name)' is not a valid scoped child reducer name.
                """
                )
              )
            )
            return
          }
          
        default:
          break
        }
        
      default:
        XCTFail(
          """
          @\(attribute) had unexpected argument named "\(argument.label?.text ?? "(nil)")"
          """
        )
        continue
      }
    }

    let closureShorthand: ClosureShorthandParameterListSyntax = ClosureShorthandParameterListSyntax
    {
      ClosureShorthandParameterSyntax(
        name: .identifier("oldValue"), trailingComma: .commaToken(trailingTrivia: .space))
      ClosureShorthandParameterSyntax(name: .identifier("newValue"), trailingTrivia: .space)
    }

    let closureSignature = ClosureSignatureSyntax(
      parameterClause: .simpleInput(closureShorthand), trailingTrivia: .newline)

    let reduceCall = signature.bodyMember(name: node.name, actionKeyPath: "", elementKeyPath: "")

    let closure = ClosureExprSyntax(
      signature: closureSignature
    ) {
      reduceCall.reducerBuilder
    }

    let onChange = BodyMember(
      name: .identifier("onChange"),
      argumentList: {
        LabeledExprSyntax(label: "of", expression: KeyPathExprSyntax(keyPath: stateKeyPath))
      },
      closure: closure
    )

    switch attachment {
    case .binding:
      guard var bindingReducer = composition.bindingReducer else {
        XCTFail("Binding reducer unexpectedly not found")
        return
      }
      bindingReducer.modifiers.append(onChange)
      composition.bindingReducer = bindingReducer
      
    case let .scope(childName):
      guard var childReducer = composition.childReducers[childName] else {
        XCTFail("Child reducer unexpectedly not found")
        return
      }
      childReducer.modifiers.append(onChange)
      composition.childReducers[childName] = childReducer
      
    case nil,
        .core:
      composition.bodyCoreModifiers.append(onChange)
    }
  }

  func processActionCase(_ node: EnumDeclSyntax, attribute: AttributeSyntax) {
    let type = node.name.text
    var name = ""

    if case let .argumentList(argumentList) = attribute.arguments {
      for argument in argumentList {
        if argument.label == nil {
          name =
            argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription ?? ""
        }
      }
    }

    // Default rule for empty name.
    if name.isEmpty {
      name = type.lowerFirst().deletingSuffix("Action")
    }

    if name.isEmpty {
      composition.context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroExpansionErrorMessage(
            "name could not be inferred, please provide an explicit name.")
        )
      )
      return
    }

    composition.addAction(name: name, type: type.scopedWith(scopeNames), sourceSyntax: attribute)
  }

  @discardableResult
  func processPlaceholder(
    type: String, attribute: AttributeSyntax, casePath: PartialCaseKeyPath<ChildType>
  ) -> String? {
    let scopedType = type.scopedWith(scopeNames)
    var name = ""

    if case let .argumentList(argumentList) = attribute.arguments {
      for argument in argumentList {
        if argument.label == nil {
          name =
            argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription ?? ""
        }
      }
    }

    guard
      let resolvedName = composition.placeholders.updatePlaceholderType(
        casePath: casePath, name: name, type: scopedType)
    else {
      composition.context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroExpansionErrorMessage(
            """
            Could not find a match for "\(name)", macro will be ignored.
            """
          )
        )
      )
      return nil
    }
    return resolvedName
  }

  func processScopePath(_ node: VariableDeclSyntax, attribute: AttributeSyntax) {
    guard case let .argumentList(argumentList) = attribute.arguments,
      let actionExpr = argumentList.first,
      actionExpr.label?.text == "action",
      node.bindings.count == 1,
      let binding = node.bindings.first,
      let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
      let stateType = binding.typeAnnotation?.type.trimmedDescription
    else {
      // TODO: Possibly need to loosen this up to support different var decl types. Put this diag here for now
      composition.context.diagnose(
        Diagnostic(
          node: attribute,
          message: MacroExpansionErrorMessage(
            """
            Could not apply @\(MacroNames.composeScopePath) to this variable declartion. Please file an issue on github.
            """
          )
        )
      )
      return
    }

    // TODO: Verify actionKeyPath is a keypath off of Action.
    let actionKeyPath = actionExpr.expression.trimmedDescription
    // TODO: should we prefix with State?
    let stateKeyPath = "\\State.\(name)"

    // Defer action type resolution until we haved visited all reducer declarations.
    composition.unresolvedScopes.append(
      .init(
        name: name,
        type: .userScope(stateType),
        keyPaths: .init(action: actionKeyPath, state: stateKeyPath))
    )
  }
}

extension MacroExpansionErrorMessage {

  static func nameNotAllowedInSignature(attribute: AttributeSyntax, name: String)
    -> MacroExpansionErrorMessage
  {
    MacroExpansionErrorMessage(
      """
      @\(attribute.attributeName.trimmedDescription) doesn't allow a parameter named "\(name)" in the function signature.
      """
    )
  }
}

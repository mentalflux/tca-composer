import CasePaths
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

@CasePathable
enum ReducerContext {
  case root
  case navigationDestination(name: String, parentType: String)
  case navigationPath(name: String, parentType: String)

  var name: String {
    switch self {
    case let .navigationDestination(name: name, _),
      let .navigationPath(name: name, _):
      name
    default:
      "#error"
    }
  }

  var parentType: String {
    switch self {
    case let .navigationDestination(_, parentType: parentType),
      let .navigationPath(_, parentType: parentType):
      parentType
    default:
      "#error"
    }
  }
}

struct ActionMember {
  let name: String
  let type: String
}

struct BodyMember {
  let name: TokenSyntax
  @LabeledExprListBuilder let argumentList: () -> LabeledExprListSyntax
  let closure: ClosureExprSyntax?

  var reducerBuilder: FunctionCallExprSyntax {
    FunctionCallExprSyntax(
      callee: DeclReferenceExprSyntax(
        baseName: name
      ),
      trailingClosure: closure,
      argumentList: argumentList
    )
  }

  enum Position: String {
    case afterCore
    case beforeCore
    case core
  }

  init(
    name: TokenSyntax,
    @LabeledExprListBuilder argumentList: @escaping () -> LabeledExprListSyntax = { [] },
    closure: ClosureExprSyntax? = nil
  ) {
    self.name = name
    self.argumentList = argumentList
    self.closure = closure
  }

  func modify(wrap: FunctionCallExprSyntax) -> FunctionCallExprSyntax {
    var formattedWrap = wrap
    formattedWrap.trailingTrivia = .newline

    return FunctionCallExprSyntax(
      callee: MemberAccessExprSyntax(
        base: formattedWrap,
        declName: DeclReferenceExprSyntax(
          baseName: name
        )
      ),
      trailingClosure: closure,
      argumentList: argumentList
    )
  }
}

struct ScopedChildReducer {
  let name: String
  let keyPaths: ScopeKeyPaths
  let reducer: (() -> FunctionCallExprSyntax?)?
  let functionName: TokenSyntax

  init(
    name: String,
    functionName: TokenSyntax = Identifiers.Scope,
    useBinding: Bool = false,
    reducer: (() -> FunctionCallExprSyntax?)? = nil
  ) {
    self.name = name
    self.functionName = functionName
    let bindingAccess = useBinding ? "$" : ""
    // NB: Do not fully qualify stateKeyPath in case the destination State is an enum.
    let stateKeyPath = ".\(bindingAccess)\(name)"
    self.keyPaths = .init(action: "\\Action.Cases.\(name)", state: stateKeyPath)
    self.reducer = reducer
  }

  var reducerBuilderMember: BodyMember {
    buildBodyMember()
  }

  var coreBodyModifier: BodyMember {
    buildBodyMember(labeledState: false)
  }

  private func buildBodyMember(labeledState: Bool = true) -> BodyMember {
    var closure: ClosureExprSyntax? = nil

    if let reducerExpr = reducer?() {
      closure = ClosureExprSyntax {
        reducerExpr
      }
    }

    // Convert Scope to ifCaseLet for body modifier.
    let adjustedFunctionName = (functionName.text == Identifiers.Scope.text && labeledState == false)
    ? .identifier("ifCaseLet")
    : functionName
    
    return BodyMember(
      name: adjustedFunctionName,
      argumentList: {
        if labeledState {
          LabeledExprSyntax(label: "state", expression: keyPaths.stateSyntax)
        } else {
          LabeledExprSyntax(expression: keyPaths.stateSyntax)
        }
        LabeledExprSyntax(label: "action", expression: keyPaths.actionSyntax)
      },
      closure: closure)
  }
}

struct StateMember {
  let name: String
  let type: String
  let initialValue: String?
  let presents: Bool

  var associatedValue: String {
    if type == "Void" {
      return ""
    }
    // TODO: Add initialValue support
    if type.hasPrefix("("),
      type.hasSuffix(")")
    {
      return type
    } else {
      let initialValueAssignment = if let initialValue { " = \(initialValue)" } else { "" }
      return "(\(type)\(initialValueAssignment))"
    }
  }

  init(name: String, type: String, initialValue: String? = nil, presents: Bool = false) {
    self.name = name
    self.type = type
    self.initialValue = initialValue
    self.presents = presents
  }
}

struct ScopeCase {
  let name: String
  let type: ChildType
  let keyPaths: ScopeKeyPaths
}

struct ScopePath {
  let name: String
  let type: ChildType
  let keyPaths: ScopeKeyPaths
  let adjustedStateType: String?
  let adjustedActionType: String?

  var stateType: String {
    adjustedStateType ?? type.stateTypeName ?? "#error"
  }

  var actionType: String {
    adjustedActionType ?? type.actionTypeName ?? "#error"
  }

  init(
    name: String,
    type: ChildType,
    keyPaths: ScopeKeyPaths,
    adjustedStateType: String? = nil,
    adjustedActionType: String? = nil
  ) {
    self.name = name
    self.type = type
    self.keyPaths = keyPaths
    self.adjustedStateType = adjustedStateType
    self.adjustedActionType = adjustedActionType
  }

  func resolveActionType(_ resolvedActionType: String) -> Self {
    .init(
      name: name,
      type: type,
      keyPaths: keyPaths,
      adjustedStateType: adjustedStateType,
      adjustedActionType: resolvedActionType
    )
  }
}

@CasePathable
enum ChildType {
  case alert(String, presentable: Bool = false)
  case confirmationDialog(String, presentable: Bool = false)
  case identifiedArray(String)
  case navigationDestination(String, childrenSyntax: LabeledExprSyntax?)
  case navigationStack(String, childrenSyntax: LabeledExprSyntax?)
  case reducer(String, optional: Bool = false, presentable: Bool = false)
  case state(String, presentable: Bool = false)
  case stateless
  case tupleState(TupleExprSyntax, presentable: Bool = false)
  case userScope(String)

  var actionTypeName: String? {
    switch self {
    case let .alert(name, presentable: presentable),
      let .confirmationDialog(name, presentable: presentable):
      return presentationAction(name, presentable: presentable)

    case let .identifiedArray(name):
      return "IdentifiedActionOf<\(name)>"

    case let .navigationDestination(name, _):
      return presentationAction("\(name).Action", presentable: true)

    case let .navigationStack(name, _):
      return "StackAction<\(name).State, \(name).Action>"

    case let .reducer(name, _, presentable):
      return presentationAction("\(name).Action", presentable: presentable)

    case .state, .stateless, .tupleState, .userScope:
      return nil
    }
  }

  var stateTypeName: String? {
    switch self {
    case let .alert(name, presentable: true):
      return "AlertState<\(name)>?"

    case let .alert(name, presentable: false):
      return "AlertState<\(name)>"

    case let .confirmationDialog(name, true):
      return "ConfirmationDialogState<\(name)>?"

    case let .confirmationDialog(name, false):
      return "ConfirmationDialogState<\(name)>"

    case let .identifiedArray(name):
      return "IdentifiedArrayOf<\(name).State>"

    case let .navigationDestination(name, _):
      return "\(name).State?"

    case let .navigationStack(name, _):
      return "StackState<\(name).State>"

    case let .reducer(name, optional: optional, presentable: presentable):
      let optionalString = optional || presentable ? "?" : ""
      return "\(name).State\(optionalString)"

    case let .state(name, true):
      return "\(name)?"

    case let .state(name, false):
      return name

    case .stateless:
      return "Void"

    case let .tupleState(tupleExpr, _):
      return tupleExpr.trimmedDescription

    case let .userScope(name):
      return name
    }
  }

  var reducerType: String? {
    switch self {
    case let .identifiedArray(name),
      let .navigationDestination(name, _),
      let .navigationStack(name, _),
      let .reducer(name, _, _):
      return name
    default:
      return nil
    }
  }

  var isPresentable: Bool {
    switch self {
    case let .alert(_, presentable: presentable),
      let .confirmationDialog(_, presentable: presentable),
      let .reducer(_, _, presentable: presentable),
      let .state(_, presentable: presentable),
      let .tupleState(_, presentable: presentable):
      return presentable

    case .navigationDestination:
      return true

    default:
      return false
    }
  }

  private func presentationAction(_ name: String, presentable: Bool) -> String {
    return presentable ? "PresentationAction<\(name)>" : name
  }

}

struct ScopeKeyPaths {
  let action: String
  let state: String

  let actionSyntax: KeyPathExprSyntax
  let stateSyntax: KeyPathExprSyntax

  init(action: String, state: String) {
    self.action = action
    self.state = state

    self.actionSyntax = .init(keyPath: action)
    self.stateSyntax = .init(keyPath: state)
  }
}

struct ReduceMethodSignature {
  let parameters: [Parameter]
  let returnType: String?

  struct Parameter: Equatable {
    let name: String
    let type: String
    let isInOut: Bool

    init(name: String, type: String, isInOut: Bool = false) {
      self.name = name
      self.type = type
      self.isInOut = isInOut
    }

  }

  var actionType: String? {
    parameters.filter({ $0.name == "action" }).map({ $0.type }).first
  }

  func bodyMember(name: TokenSyntax, actionKeyPath: String, elementKeyPath: String) -> BodyMember {
    let closureShorthand: ClosureShorthandParameterListSyntax = ClosureShorthandParameterListSyntax
    {
      ClosureShorthandParameterSyntax(
        name: .identifier("state"), trailingComma: .commaToken(trailingTrivia: .space))
      if !elementKeyPath.isEmpty {
        ClosureShorthandParameterSyntax(
          name: .identifier("id"), trailingComma: .commaToken(trailingTrivia: .space))
      }
      ClosureShorthandParameterSyntax(name: .identifier("action"), trailingTrivia: .space)
    }

    let closureSignature = ClosureSignatureSyntax(
      parameterClause: .simpleInput(closureShorthand), trailingTrivia: .newline)

    let functionCall = FunctionCallExprSyntax(
      callee: MemberAccessExprSyntax(
        base: DeclReferenceExprSyntax(baseName: .keyword(.self)),
        name: name)
    ) {
      for parameter in parameters {
        if parameter.isInOut {
          LabeledExprSyntax(
            label: parameter.name,
            expression: InOutExprSyntax(
              expression: DeclReferenceExprSyntax(baseName: .identifier(parameter.name))))
        } else {
          LabeledExprSyntax(
            label: parameter.name,
            expression: DeclReferenceExprSyntax(baseName: .identifier(parameter.name)))
        }
      }
    }

    let closure = ClosureExprSyntax(
      signature: closureSignature
    ) {
      if returnType != nil {
        ReturnStmtSyntax(
          returnKeyword: .keyword(.return, trailingTrivia: .space),
          expression: functionCall)
      } else {
        functionCall
        ReturnStmtSyntax(
          leadingTrivia: .newline,
          returnKeyword: .keyword(.return, trailingTrivia: .space),
          expression: MemberAccessExprSyntax(
            declName: DeclReferenceExprSyntax(baseName: .identifier("none")))
        )
      }
    }

    let reducerName =
      if actionKeyPath.isEmpty {
        Identifiers.Reduce
      } else if elementKeyPath.isEmpty {
        Identifiers.ReduceAction
      } else {
        Identifiers.ReduceIdentifiedAction
      }

    return BodyMember(
      name: reducerName,
      argumentList: {
        if !actionKeyPath.isEmpty {
          LabeledExprSyntax(expression: KeyPathExprSyntax(keyPath: actionKeyPath))
        }
        if !elementKeyPath.isEmpty {
          LabeledExprSyntax(
            label: "element", expression: KeyPathExprSyntax(keyPath: elementKeyPath))
        }
      },
      closure: closure
    )
  }
}

struct TypePlaceholders {
  var placeholders = [String: Placeholder]()

  struct Placeholder {
    let type: ChildType
    let sourceSyntax: SyntaxProtocol

    func updateType(_ type: ChildType) -> Placeholder {
      Placeholder(type: type, sourceSyntax: self.sourceSyntax)
    }
  }

  subscript(_ name: String) -> Placeholder? {
    get {
      placeholders[name]
    }
    set {
      placeholders[name] = newValue
    }
  }

  subscript(case: PartialCaseKeyPath<ChildType>, name: String) -> Placeholder? {
    placeholders.first(where: { $0 == name && $1.type.is(`case`) })?.value
  }

  func filter(name: String) -> TypePlaceholders {
    var filteredMappings = [String: Placeholder]()
    for (key, value) in placeholders {
      let destinationAlertName = key.deletingPrefix("\(name).")

      if key.hasPrefix("\(name).") {
        filteredMappings[destinationAlertName] = value
      }
    }
    return TypePlaceholders(placeholders: filteredMappings)
  }

  mutating func updatePlaceholderType(
    casePath: PartialCaseKeyPath<ChildType>, name: String, type: String
  ) -> String? {
    if name.isEmpty {
      let typePlaceholders = placeholders.filter({ $0.value.type.is(casePath) })
      guard typePlaceholders.count == 1,
        let placeholder = typePlaceholders.first
      else {
        return nil
      }
      return updatePlaceholderType(
        name: placeholder.key, placeholder: placeholder.value, type: type)
    } else {
      guard let placeholder = self[casePath, name] else {
        return nil
      }
      return updatePlaceholderType(name: name, placeholder: placeholder, type: type)
    }
  }

  private mutating func updatePlaceholderType(name: String, placeholder: Placeholder, type: String)
    -> String?
  {
    switch placeholder.type {
    case .alert:
      placeholders[name] = placeholder.updateType(
        .alert(type, presentable: placeholder.type.isPresentable))
      return name

    case .confirmationDialog:
      placeholders[name] = placeholder.updateType(
        .confirmationDialog(type, presentable: placeholder.type.isPresentable))
      return name

    default:
      return nil
    }
  }

}

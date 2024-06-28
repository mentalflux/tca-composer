import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct Composer {
  let composition: Composition
  let reducerDecl: StructDeclSyntax
  let context: MacroExpansionContext

  init(
    _ reducerDecl: StructDeclSyntax,
    context: MacroExpansionContext,
    reducerContext: ReducerContext = .root,
    placeholders: TypePlaceholders = .init()
  ) {
    self.reducerDecl = reducerDecl
    self.context = context

    let composeReducerAttrs = reducerDecl.attributes.allAttributes(
      matching: [
        MacroNames.composeReducer,
        MacroNames.composeEnumReducer,
      ])

    guard composeReducerAttrs.count == 1,
      let composeReducerAttr = composeReducerAttrs.first
    else {
      // TODO: diagnostic for the case of multilple @ComposeReducer attrs?
      self.composition = Composition(reducerDecl: reducerDecl, context: context)
      return
    }

    self.composition = Composition(
      reducerDecl: reducerDecl,
      context: context,
      attribute: composeReducerAttr,
      placeholders: placeholders,
      reducerContext: reducerContext)
  }

  func composeMembers() -> [DeclSyntax] {
    composition.analyze()

    var decls: [DeclSyntax] = []

    if composition.isMissingStateDeclaration {
      decls.append(composeMissingState())
    }

    decls.append(composeMissingAction())
    
    if composition.isMissingBodyDeclaration {
      decls.append(composeBody())
    }
    else if let bodyDecl = composition.bodyDecl {
      context.diagnose(
        Diagnostic(
          node: bodyDecl,
          message: MacroExpansionWarningMessage(
            """
            @Composer `body` generation suppressed. Delete or rename `body` to enable.
            """
          )
        )
      )
    }

    if composition.needsScopePaths {
      decls.append(composeScopePaths())
    }

    if composition.needsScopeCases {
      decls.append(composeScopeCases())
    }

    if composition.hasNavigationReducers {
      decls += composeNavigationReducers()
    }

    return decls
  }

  func composeMissingState() -> DeclSyntax {
    return composition.isStateEnum
      ? composeMissingStateEnum()
      : composeMissingStateStruct()
  }

  // TODO: Refactor and align with composeMissingStateStruct
  func composeMissingStateEnum() -> DeclSyntax {
    let conformances = composition.confromancesForState
    let conformanceExpr = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"

    var scopeSwitchable = ""

    // TODO: inline this?
    if composition.needsScopeCases {
      scopeSwitchable = "@_ComposerScopeSwitchable\n"
    }

    var decls: [DeclSyntax] = []
    for stateMember in composition.stateMembers {
      decls.append(
        """
        case \(raw: stateMember.name)\(raw: stateMember.associatedValue)
        """
      )
    }

    var initializer = ""
    if let enumeratedStateInitialValueMember = composition.enumeratedStateInitialValueMember {
      let initialValueAssigment = enumeratedStateInitialValueMember.initialValue == nil ? "" : "()"
      initializer =
        "\n\(composition.accessModifier)init() { self = .\(enumeratedStateInitialValueMember.name)\(initialValueAssigment) }"
    }

    return """
      \(raw: scopeSwitchable)@CasePathable
      @ObservableState
      @dynamicMemberLookup
      \(raw: composition.accessModifier)enum State\(raw: conformanceExpr) {
      \(raw: decls.map(\.description).joined(separator: "\n"))\(raw: initializer)
      }
      """
  }

  func composeMissingStateStruct() -> DeclSyntax {
    let conformances = composition.confromancesForState
    let conformanceExpr = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"

    var decls: [DeclSyntax] = []
    for stateMember in composition.stateMembers {
      let presents = stateMember.presents ? "@Presents " : ""
      let initialValueAssignment =
        if let initialValue = stateMember.initialValue {
          " = \(initialValue)"
        } else {
          ""
        }

      decls.append(
        """
        \(raw: presents)\(raw: composition.accessModifier)var \(raw: stateMember.name): \(raw: stateMember.type)\(raw: initialValueAssignment)
        """
      )
    }

    let allComposedScopePaths =
      composition.needsScopePaths
      ? "\n\n\(composition.accessModifier)static var allComposedScopePaths: AllComposedScopePaths { AllComposedScopePaths() }"
      : ""
    let initializer =
      composition.accessModifier.isEmpty ? "" : "\n\(composition.accessModifier) init() {}"

    return """
      @ObservableState
      \(raw: composition.accessModifier)struct State\(raw: conformanceExpr) {
      \(raw: decls.map(\.description).joined(separator: "\n"))\(raw: initializer)\(raw: allComposedScopePaths)
      }
      """
  }

  // TODO: Convert to use Syntax nodes
  func composeMissingAction() -> DeclSyntax {
    let conformances = composition.confromancesForAction
    let conformanceExpr = conformances.isEmpty ? "" : ": \(conformances.joined(separator: ", "))"

    var decls: [DeclSyntax] = []
    for child in composition.actionMembers.sorted(by: { $0.name < $1.name }) {
      decls.append(
        """
        case \(raw: child.name)(\(raw: child.type))
        """
      )
    }

    return """
      @CasePathable
      \(raw: composition.accessModifier)enum Action\(raw: conformanceExpr) {
      \(raw: decls.map(\.description).joined(separator: "\n"))
      }
      """
  }

  func composeNavigationReducers() -> [DeclSyntax] {
    var navigationReducers = [DeclSyntax]()

    for scope in composition.scopes {
      switch scope.type {
      case let .navigationDestination(reducerName, childrenSyntax: childrenSyntax):
        navigationReducers.append(
          composeNavigationReducer(
            name: scope.name,
            reducerName: reducerName,
            childrenSyntax: childrenSyntax,
            reducerContext: .navigationDestination(
              name: scope.name, parentType: reducerDecl.name.text))
        )

      case let .navigationStack(reducerName, childrenSyntax: childrenSyntax):
        navigationReducers.append(
          composeNavigationReducer(
            name: scope.name,
            reducerName: reducerName,
            childrenSyntax: childrenSyntax,
            reducerContext: .navigationPath(name: scope.name, parentType: reducerDecl.name.text))
        )
      default:
        continue
      }
    }

    return navigationReducers
  }

  func composeNavigationReducer(
    name: String, reducerName: String, childrenSyntax: LabeledExprSyntax?,
    reducerContext: ReducerContext
  ) -> DeclSyntax {
    let navigationReducerProtoDecl: DeclSyntax =
      """
      @ComposeEnumReducer(\(raw: childrenSyntax?.description ?? ""))
      \(raw: composition.accessModifier)struct \(raw: reducerName) {}
      """

    let navigationComposer = Composer(
      navigationReducerProtoDecl.cast(StructDeclSyntax.self),
      context: context,
      reducerContext: reducerContext,
      placeholders: composition.placeholders.filter(name: name))

    navigationComposer.composition.placeholders = composition.placeholders.filter(name: name)

    // TODO: Convert to using Syntax node
    let reducerDecl: DeclSyntax =
      """
      \(raw: composition.accessModifier)struct \(raw: reducerName): ComposableArchitecture.Reducer {
      \(raw: navigationComposer.composeMembers().map(\.description).joined(separator: "\n"))
      }
      """
    return reducerDecl
  }

  func composeBody() -> DeclSyntax {
    var reducerBuilders = [FunctionCallExprSyntax]()

    for member in composition.bodyBeforeCoreMembers {
      reducerBuilders.append(member.reducerBuilder)
    }

    if composition.requiresBodyCore {
      var coreReducer =
        composition.bodyCoreMembers.isEmpty
        ? FunctionCallExprSyntax(
          callee: DeclReferenceExprSyntax(
            baseName: Identifiers.EmptyReducer
          )
        )
        : FunctionCallExprSyntax(
          callee: DeclReferenceExprSyntax(
            baseName: Identifiers.ComposeReducers
          ),
          trailingClosure: ClosureExprSyntax {
            for member in composition.bodyCoreMembers {
              member.reducerBuilder
            }
          }
        )

      for modifier in composition.bodyCoreModifiers {
        coreReducer = modifier.modify(wrap: coreReducer)
      }

      reducerBuilders.append(coreReducer)
    }

    for member in composition.bodyAfterCoreMembers {
      reducerBuilders.append(member.reducerBuilder)
    }

    if reducerBuilders.isEmpty {
      reducerBuilders.append(
        FunctionCallExprSyntax(
          callee: DeclReferenceExprSyntax(
            baseName: Identifiers.EmptyReducer
          )
        )
      )
    }

    // TODO: Generate syntax nodes directly.
    let bodyDecl: DeclSyntax =
      """
      @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
      \(raw: composition.accessModifier)var body: some ReducerOf<Self> {
      \(raw: reducerBuilders.map(\.trimmedDescription).joined(separator: "\n"))
      }
      """

    return bodyDecl
  }

  func composeAttributesForExistingEnumState(stateDecl: EnumDeclSyntax) -> [AttributeSyntax] {
    // TODO: Fix
    //    composition.options.insert(.enumeratedState)
    composition.analyze()
    return composeAttributesForStateEnum()
  }

  // Provides attributes for the specified sruct declaration. If nil, then that indicates State is being completely generated
  func composeAttributesForState(stateDecl: StructDeclSyntax? = nil) -> [AttributeSyntax] {
    composition.analyze()
    var attributes: [AttributeSyntax] = []

    if composition.isStateEnum {
      attributes = composeAttributesForStateEnum()
    } else {
      attributes = composeAttributesForStateStruct()
    }

    if !(stateDecl?.attributes.hasMacroApplication("ObservableState") ?? false) {
      attributes.append(
        """
        @ObservableState
        """
      )
    }
    return attributes
  }

  func composeAttributesForStateStruct(stateDecl: StructDeclSyntax? = nil) -> [AttributeSyntax] {
    var decls: [AttributeSyntax] = []

    if composition.reducerContext.is(\.navigationPath) {
      decls.append(
        """
        @_ComposerScopeSwitchable
        """
      )
    } else if composition.needsScopePaths {
      decls.append(
        """
        @_ComposerScopePathable
        """
      )
    }

    for member in composition.stateMembers {
      var optionalArgs = ""
      if let initialValue = member.initialValue {
        optionalArgs += ", initialValue: \(initialValue)"
      }
      if member.presents {
        optionalArgs += ", options: .presents"
      }
      decls.append(
        """
        @_ComposedStateMember("\(raw: member.name)", of: \(raw: member.type).self\(raw: optionalArgs))
        """
      )
    }
    return decls
  }

  func composeAttributesForStateEnum() -> [AttributeSyntax] {
    var decls: [AttributeSyntax] = []

    decls.append(
      """
      @_ComposerCasePathable
      """
    )
    return decls
  }

  // TODO: Convert to directly construct Syntax nodes.
  func composeScopePaths() -> DeclSyntax {
    var decls = [DeclSyntax]()

    var baseReducerName = reducerDecl.name.text

    switch composition.reducerContext {
    case let .navigationDestination(name: _, parentType: parentType),
      let .navigationPath(name: _, parentType: parentType):
      baseReducerName = parentType
    default:
      break
    }

    let reducerState = "\(baseReducerName).State"
    let reducerAction = "\(baseReducerName).Action"

    let scopePaths = "TCAComposer.ScopePath"

    for scope in composition.scopes {
      if case let .navigationDestination(typeName, _) = scope.type {
        decls.append(
          """
          \(raw: composition.accessModifier)var \(raw: scope.name): \(raw: typeName).AllComposedScopePaths {
          get {
          return \(raw: typeName).AllComposedScopePaths()
          }
          }
          """
        )
      } else {
        decls.append(
          """
          \(raw: composition.accessModifier)var \(raw: scope.name): \(raw:scopePaths)<\(raw: reducerState), \(raw: scope.stateType), \(raw: reducerAction), \(raw: scope.actionType)> {
          get {
          return \(raw: scopePaths)(state: \(raw: scope.keyPaths.state), action: \(raw: scope.keyPaths.action))
          }
          }
          """
        )
      }
    }

    let scopePathsDecl: DeclSyntax =
      """
      \(raw: composition.accessModifier)struct AllComposedScopePaths {
      \(raw: decls.map(\.description).joined(separator: "\n"))
      }
      """

    return scopePathsDecl
  }

  // TODO: Convert to directly construct Syntax nodes.
  func composeScopeCases() -> DeclSyntax {
    var decls = [DeclSyntax]()
    var switchCases = [String]()

    let reducerName = reducerDecl.name.text

    for scopeCase in composition.scopeCases {
      switch scopeCase.type {
      case .reducer:
        switchCases.append(
          """
          case .\(scopeCase.name):
            return .\(scopeCase.name)(store: store.scope(state: \(scopeCase.keyPaths.state), action: \(scopeCase.keyPaths.action))!)
          """
        )
        if let stateType = scopeCase.type.stateTypeName,
          let actionType = scopeCase.type.actionTypeName
        {
          decls.append(
            """
            case \(raw: scopeCase.name)(store: Store<\(raw: stateType), \(raw: actionType)>)
            """
          )
        }
      case let .state(name, _):
        switchCases.append(
          """
          case let .\(scopeCase.name)(v0):
            return .\(scopeCase.name)(v0)
          """
        )
        decls.append(
          """
          case \(raw: scopeCase.name)(\(raw: name))
          """
        )
      case .stateless:
        switchCases.append(
          """
          case .\(scopeCase.name):
            return .\(scopeCase.name)
          """
        )
        decls.append(
          """
          case \(raw: scopeCase.name)
          """
        )
      case let .tupleState(tupleExpr, _):
        decls.append(
          """
          case \(raw: scopeCase.name)\(raw: tupleExpr.trimmedDescription)
          """
        )

        var parameters = [String]()
        for element in tupleExpr.elements {
          let label = if let elementLabel = element.label { "\(elementLabel): " } else { "" }
          parameters.append("\(label)v\(parameters.count)")
        }
        let parameterList = parameters.joined(separator: ", ")

        switchCases.append(
          """
          case let .\(scopeCase.name)(\(parameterList)):
            return .\(scopeCase.name)(\(parameterList))
          """
        )
      default:
        continue
      }
    }

    let scopePathsDecl: DeclSyntax =
      """
      \(raw: composition.accessModifier)struct AllComposedScopeCases: TCAComposer.ScopeCases {
      \(raw: composition.accessModifier)typealias State = \(raw: reducerName).State
      \(raw: composition.accessModifier)typealias Action = \(raw: reducerName).Action

      \(raw: composition.accessModifier)static func scopedState(store: StoreOf<\(raw: reducerName)>) -> ScopedState {
      switch store.state {
      \(raw: switchCases.joined(separator: "\n"))
      }
      }

      @CasePathable
      \(raw: composition.accessModifier)enum ScopedState: CasePaths.CasePathable  {
      \(raw: decls.map(\.description).joined(separator: "\n"))
      }
      }
      """

    return scopePathsDecl
  }
}

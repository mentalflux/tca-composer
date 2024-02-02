import OrderedCollections
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum _ComposedActionMacro: ExtensionMacro {

  struct Arguments {
    // TODO: investigate this issue again. Maybe just go with alphanumeric sort?
    // NB: This has to be an ordered set for tests to reliably pass. Extensions should be emitted in the order declared in macro
    var options = OrderedSet<Option>()

    enum Option: String {
      case bindableAction
      case viewAction

      func extensionDecl(type: TypeSyntaxProtocol) -> ExtensionDeclSyntax? {
        switch self {
        case .bindableAction,
          .viewAction:
          let name = "\(self)"
          let actionType = name.prefix(1).capitalized + name.dropFirst()
          let ext: DeclSyntax =
            """
            extension \(raw: type.trimmedDescription): ComposableArchitecture.\(raw: actionType) {}
            """
          return ext.as(ExtensionDeclSyntax.self)
        }
      }
    }

    init() {}

    init?(_ attribute: AttributeSyntax) {
      guard case let .argumentList(argumentList) = attribute.arguments else {
        return nil
      }
      for argument in argumentList {
        guard let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
          let option = Option(rawValue: memberAccessExpr.declName.trimmedDescription)
        else {
          continue
        }
        options.append(option)
      }
    }

    func macroDecl() -> AttributeSyntax {
      let joined = options.map { ".\($0)" }.joined(separator: ", ")
      let attribute: AttributeSyntax =
        """
        @_ComposedAction(\(raw: joined))
        """
      return attribute
    }
  }

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Type: TypeSyntaxProtocol,
    Context: MacroExpansionContext
  >(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: Declaration,
    providingExtensionsOf type: Type,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: Context
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard let arguments = Arguments(node) else {
      return []
    }
    return arguments.options.compactMap { $0.extensionDecl(type: type) }
  }

}

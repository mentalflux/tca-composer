import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum _ComposedStateMemberMacro: MemberMacro {

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let arguments = Arguments(attribute: node, context: context) else {
      return []
    }

    let observationStateTracked = "@ObservationStateTracked"
    var decls: [DeclSyntax] = []

    var varMacro = ""

    if arguments.isPresentable {
      varMacro = "@Presents"
    } else {
      varMacro = observationStateTracked
    }

    var initalValueAssignment = ""
    if let initialValue = arguments.initialValue {
      initalValueAssignment = " = \(initialValue)"
    }

    let accessModifier =
      declaration.modifiers.first(where: \.isNeededAccessLevelModifier)?.trimmedDescription
      .appending(" ") ?? ""

    let varDecl: DeclSyntax =
      """
      \(raw: varMacro)
      \(raw: accessModifier)var \(raw: arguments.name): \(raw: arguments.type)\(raw: initalValueAssignment)
      """

    decls.append(varDecl)

    if !arguments.isPresentable {
      let obervationVarDecl: DeclSyntax =
        """
        @ObservationStateIgnored
        private var _\(raw: arguments.name): \(raw: arguments.type)
        """

      decls.append(obervationVarDecl)
    }

    return decls

  }

  struct Arguments {

    var name = ""
    var type = ""
    var options = Set<Option>()
    var initialValue: String?

    var isPresentable: Bool {
      options.contains(.presents)
    }

    enum Option: String {
      case presents
    }

    init?(attribute: AttributeSyntax, context: MacroExpansionContext) {
      guard
        case let .argumentList(argumentList) = attribute.arguments,
        argumentList.count >= 2
      else {
        return nil
      }

      for argument in argumentList {
        switch argument.label?.text {
        case "of":
          type = String(argument.expression.trimmedDescription.dropLast(5))

        case "initialValue":
          initialValue = argument.expression.trimmedDescription

        case "options":
          if let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
            let option = Option(rawValue: memberAccessExpr.declName.trimmedDescription)
          {
            options.insert(option)
          }
        case nil:
          name =
            argument.expression.as(StringLiteralExprSyntax.self)?.segments.trimmedDescription ?? ""

        default:
          // Unknown argument, Diagnostic?
          return nil
        }
      }

      if name == "" || type == "" {
        // Failed to find name or type. Diagnostic?
        return nil
      }

      if type.hasPrefix("IdentifiedArrayOf<"),
        initialValue == nil
      {
        // Always provide an initial value for IdentifiedArrays
        initialValue = "[]"
      }
    }
  }
}

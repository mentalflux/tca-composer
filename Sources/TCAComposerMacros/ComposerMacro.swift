import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import IssueReporting

#if !canImport(SwiftSyntax600)
import SwiftSyntaxMacroExpansion
#endif

public enum ComposerMacro {
}

extension ComposerMacro: ExtensionMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax, ExtensionType: TypeSyntaxProtocol, Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    attachedTo declaration: Declaration,
    providingExtensionsOf type: ExtensionType,
    conformingTo protocols: [TypeSyntax],
    in context: Context
  ) throws -> [ExtensionDeclSyntax] {

    guard let reducerDecl = declaration.as(StructDeclSyntax.self) else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            "@Composer can only be applied to struct declarations."))
      ])
    }

    if let reducerAttribute = reducerDecl.attributes.firstAttribute(for: "Reducer") {
      let filteredList = reducerDecl.attributes.filter({
        !$0.tokens(viewMode: .all).map({ $0.tokenKind }).contains(.identifier("Reducer"))
      })

      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: reducerAttribute,
          message: MacroExpansionErrorMessage(
            "@Reducer cannot be used in combination with @Composer."),
          fixIt: .replace(
            message: MacroExpansionFixItMessage("Remove @Reducer."),
            oldNode: declaration.attributes,
            newNode: filteredList)
        )
      ])
    }

    if let inheritanceClause = reducerDecl.inheritanceClause,
      inheritanceClause.inheritedTypes.contains(
        where: {
          ["Reducer"].withTCAQualified.contains($0.type.trimmedDescription)
        }
      )
    {
      return []
    }

    let ext: DeclSyntax =
      """
      extension \(type.trimmed): ComposableArchitecture.Reducer {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension ComposerMacro: MemberMacro {

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let reducerDecl = declaration.as(StructDeclSyntax.self) else {
      // NB: The diagnostic is handled by the extension macro, so this should never happen.
      return []
    }
    return Composer(reducerDecl, context: context).composeMembers()
  }

}

extension ComposerMacro: MemberAttributeMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Member: DeclSyntaxProtocol,
    Context: MacroExpansionContext
  >(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: Declaration,
    providingAttributesFor member: Member,
    in context: Context
  ) throws -> [SwiftSyntax.AttributeSyntax] {

    guard let reducerDecl = declaration.as(StructDeclSyntax.self) else {
      // NB: The diagnostic is handled by the extension macro, so this should never happen.
      return []
    }

    if let enumDecl = member.as(EnumDeclSyntax.self) {
      switch enumDecl.name.trimmedDescription {
      case "Action":
        throw DiagnosticsError(diagnostics: [
          Diagnostic(
            node: enumDecl,
            message: MacroExpansionErrorMessage(
              "@Composer automatically generates the `Action` enum, please rename or remove.")
          )
        ])

      case "Actions":
        // TODO: check if already applied?
        return [
          """
          @_ComposerCasePathableActions
          """
        ]

      case "State":
        return Composer(reducerDecl, context: context).composeAttributesForExistingEnumState(
          stateDecl: enumDecl)

      case let name where name.hasSuffix("Action"):
        if !enumDecl.attributes.allAttributes(
          matching: CasePathConstants.conformanceNames
        ).isEmpty {
          return []
        }

        if let inheritanceClause = enumDecl.inheritanceClause,
          inheritanceClause.inheritedTypes.contains(
            where: {
              CasePathConstants.conformanceNames.contains($0.type.trimmedDescription)
            })
        {
          return []
        }
        return [
          """
          @CasePathable
          """
        ]

      default:
        return []
      }
    } else if let structDecl = member.as(StructDeclSyntax.self),
      structDecl.name.trimmedDescription == "State"
    {
      return Composer(reducerDecl, context: context).composeAttributesForState(
        stateDecl: structDecl)
    } else {
      return []
    }
  }
}

extension Array where Element == String {
  var withTCAQualified: Self {
    self.flatMap { [$0, "ComposableArchitecture.\($0)"] }
  }
}

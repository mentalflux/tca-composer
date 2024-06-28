import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum _ComposerCasePathableActions: MemberAttributeMacro {
  
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
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      // TODO: diag?
      return []
    }

    if !enumDecl.attributes.allAttributes(matching: CasePathConstants.conformanceNames)
      .isEmpty
    {
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
  }

}

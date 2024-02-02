import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum _ComposerScopePathableMacro: MemberMacro {

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    // TODO: generate correct access for this var
    return [
      """
      public static var allComposedScopePaths: AllComposedScopePaths { AllComposedScopePaths() }
      """
    ]
  }
}

extension _ComposerScopePathableMacro: ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): \(raw: "TCAComposer.ScopePathable") {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }

}

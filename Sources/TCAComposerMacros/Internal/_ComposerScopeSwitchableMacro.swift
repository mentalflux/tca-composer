import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public enum _ComposerScopeSwitchableMacro: MemberMacro {

  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    // TODO: - generate correct access for this var
    return [
      """
      public static var allComposedScopeCases: AllComposedScopeCases { AllComposedScopeCases() }
      """
    ]
  }
}

extension _ComposerScopeSwitchableMacro: ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): \(raw: "TCAComposer.ScopeSwitchable") {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }

}

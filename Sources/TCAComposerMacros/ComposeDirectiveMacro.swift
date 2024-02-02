import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

// This macro is used for all @Compose delcarative macros. It performs limited diagnostics and generated no new code.
public enum ComposeDirectiveMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    if declaration.is(EnumDeclSyntax.self) {
      if !node.matches(MacroNames.enumComposeDirectiveMacros) {
        throw DiagnosticsError(diagnostics: [
          Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage(
              "@\(node.attributeName.trimmedDescription) cannot be applied to an enum declaration.")
          )
        ])
      }
    } else if declaration.is(FunctionDeclSyntax.self) {
      if !node.matches(MacroNames.functionComposeDirectiveMacros) {
        throw DiagnosticsError(diagnostics: [
          Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage(
              "@\(node.attributeName.trimmedDescription) cannot be applied to a function declaration."
            ))
        ])
      }
    } else if declaration.is(StructDeclSyntax.self) {
      if !node.matches(MacroNames.structComposeDirectiveMacros) {
        throw DiagnosticsError(diagnostics: [
          Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage(
              "@\(node.attributeName.trimmedDescription) cannot be applied to a struct declaration."
            ))
        ])
      }
    } else if declaration.is(VariableDeclSyntax.self) {
      if !node.matches(MacroNames.variableComposeDirectiveMacros) {
        throw DiagnosticsError(diagnostics: [
          Diagnostic(
            node: node,
            message: MacroExpansionErrorMessage(
              "@\(node.attributeName.trimmedDescription) cannot be applied to a variable declaration."
            ))
        ])
      }
    } else {
      throw DiagnosticsError(diagnostics: [
        Diagnostic(
          node: node,
          message: MacroExpansionErrorMessage(
            "@\(node.attributeName.trimmedDescription) cannot be used here."))
      ])
    }
    return []
  }
}

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

import TCAComposerMacros

// Declartion to make this macro disappear in macro test expected output
enum ComposeActionCaseMacro: PeerMacro {
  static func expansion(of node: SwiftSyntax.AttributeSyntax,
                        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeActionAlertCaseMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeActionConfirmationDialogCaseMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeAllCasePathsMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeBodyMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
enum ComposeBodyActionCaseMacro: PeerMacro {
  static func expansion(of node: SwiftSyntax.AttributeSyntax,
                        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
enum ComposeBodyActionAlertCaseMacro: PeerMacro {
  static func expansion(of node: SwiftSyntax.AttributeSyntax,
                        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
enum ComposeBodyActionConfirmationDialogCaseMacro: PeerMacro {
  static func expansion(of node: SwiftSyntax.AttributeSyntax,
                        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expect3d output
public enum ComposeBodyChildMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
enum ComposeBodyOnChangeMacro: PeerMacro {
  static func expansion(of node: SwiftSyntax.AttributeSyntax,
                        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeEnumReducerMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}


// Declartion to make this macro disappear in macro test expected output
public enum ComposeReducerMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

// Declartion to make this macro disappear in macro test expected output
public enum ComposeScopePathMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax,
                               providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
                               in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return try ComposeDirectiveMacro.expansion(of: node, providingPeersOf: declaration, in: context)
  }
}

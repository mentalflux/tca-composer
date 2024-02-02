
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

struct NameTypeArguments {
  
  let name: String
  let type: String
  
  init?(attribute: AttributeSyntax, context: MacroExpansionContext) {
    guard
      case let .argumentList(argumentList) = attribute.arguments,
      argumentList.count == 2 else {
      // TODO, Diagnostic error?
      return nil
    }
    
    let arguments = Array(argumentList)
    
    guard let nameArgument = arguments[0].expression.as(StringLiteralExprSyntax.self) else {
      // TODO: diagnostic error
      return nil
    }
    
    guard let typeArgument = arguments[1].expression.as(MemberAccessExprSyntax.self),
          typeArgument.declName.trimmedDescription == "self" else {
      // TODO: This shouldn't happen, but could produce diagnostic error?
      return nil
    }
    
    name = nameArgument.segments.trimmedDescription
    type = String(typeArgument.trimmedDescription.dropLast(5))
  }
}

public enum _ComposedActionMemberMacro: MemberMacro {
  
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard
      case let .argumentList(argumentList) = node.arguments,
      argumentList.count == 2 else {
      // TODO, Diagnostic error?
      return []
    }
    
    let arguments = Array(argumentList)
    
    guard let nameArgument = arguments[0].expression.as(StringLiteralExprSyntax.self) else {
      // TODO diagnostic error
      return []
    }
    
    guard let typeArgument = arguments[1].expression.as(MemberAccessExprSyntax.self),
          typeArgument.declName.trimmedDescription == "self" else {
      // TODO This shouldn't happen, but could produce diagnostic error?
      
      return [
         """
         case typeError
         """
      ]
    }
    
    let name = nameArgument.segments.trimmedDescription
    
    let type = typeArgument.trimmedDescription.dropLast(5)
    
    let caseDecl: DeclSyntax =
      """
      case \(raw: name)(\(raw: type))
      """
    
    // TODO clean this up
    let identDecl: ExprSyntax = "\(raw: name)"
    
    guard let _ = identDecl.as(DeclReferenceExprSyntax.self) else {
      return []
    }
    
    if caseDecl.is(EnumCaseDeclSyntax.self) {
      return [caseDecl]
    }
    else {
      return []
    }
    
  }
}

extension _ComposedActionMemberMacro: MemberAttributeMacro {
  
  public static func expansion<Declartion: DeclGroupSyntax, Member: DeclSyntaxProtocol>(of node: SwiftSyntax.AttributeSyntax,
                                                                                        attachedTo declaration: Declartion,
                                                                                        providingAttributesFor member: Member,
                                                                                        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
    guard let arguments = NameTypeArguments(attribute: node, context: context),
          let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      return []
    }
    
    if let structDecl = member.as(StructDeclSyntax.self) {
      guard structDecl.name.text == _ComposerCasePathableMacro.allCasePathsTypeName else {
        // TODO: Diagnostic
        return []
      }
      
      return [
        """
        @_ComposedCasePathMember(enumName: "\(raw: enumDecl.name.trimmed)", caseName: "\(raw: arguments.name)", of: \(raw: arguments.type).self)
        """
      ]
    }
    else {
      return []
    }
  }
}

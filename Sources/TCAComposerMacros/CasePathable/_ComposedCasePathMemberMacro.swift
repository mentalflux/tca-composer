/**
 MIT License
 
 Copyright (c) 2020 Point-Free, Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

struct EnumNameTypeArguments {
  
  let caseName: String
  let enumName: String
  let type: String
  
  init?(attribute: AttributeSyntax, context: MacroExpansionContext) {
    guard
      case let .argumentList(argumentList) = attribute.arguments,
      argumentList.count == 3 else {
      // TODO, Diagnostic error?
      return nil
    }
    
    let arguments = Array(argumentList)
    
    guard let enumNameArgument = arguments[0].expression.as(StringLiteralExprSyntax.self) else {
      // TODO diagnostic error
      return nil
    }
    
    guard let caseNameArgument = arguments[1].expression.as(StringLiteralExprSyntax.self) else {
      // TODO diagnostic error
      return nil
    }
    
    guard let typeArgument = arguments[2].expression.as(MemberAccessExprSyntax.self),
          typeArgument.declName.trimmedDescription == "self" else {
      // TODO This shouldn't happen, but could produce diagnostic error?
      return nil
    }
    
    enumName = enumNameArgument.segments.trimmedDescription
    caseName = caseNameArgument.segments.trimmedDescription
    type = String(typeArgument.trimmedDescription.dropLast(5))
  }
}

public enum _ComposedCasePathMemberMacro: MemberMacro {
  
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self),
          let arguments = EnumNameTypeArguments(attribute: node, context: context) else {
      return []
    }
    let access = structDecl.modifiers.first(where: \.isNeededAccessLevelModifier)
    
    let enumCaseElement = arguments.type == "Void" ? "" : "(\(arguments.type))"

    let decl: DeclSyntax =
      """
      enum \(raw: arguments.enumName) {
          case \(raw: arguments.caseName)\(raw: enumCaseElement)
      }
      """
    
    guard let enumDecl = decl.as(EnumDeclSyntax.self) else {
      // Diagnostics
      return []
    }
    let enumName = enumDecl.name.trimmed
    let members = enumDecl.memberBlock.members
    
    let casePaths = _ComposerCasePathableMacro.generateDeclSyntax(from: members, with: access, enumName: enumName)
    //        let typedEnumCaseDecl = enumCaseDecl.cast(enumCaseDecl)
    
    //        if let elements = $0.decl.as(EnumCaseDeclSyntax.self)?.elements {
    //          return generateDeclSyntax(from: elements, with: access, enumName: enumName)
    //        }
    return casePaths
    
  }
}

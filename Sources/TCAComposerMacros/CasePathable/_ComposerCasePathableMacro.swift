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
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct _ComposerCasePathableMacro {
  static let moduleName = "CasePaths"
  static let conformanceName = "CasePathable"
  static let allCasePathsTypeName = "AllCasePaths"
  static var qualifiedConformanceName: String { "\(Self.moduleName).\(Self.conformanceName)" }
  static var conformanceNames: [String] { [Self.conformanceName, Self.qualifiedConformanceName] }
  static let casePathTypeName = "AnyCasePath"
  static var qualifiedCasePathTypeName: String { "\(Self.moduleName).\(Self.casePathTypeName)" }
  static var qualifiedCaseTypeName: String { "\(Self.moduleName).Case" }
}

extension _ComposerCasePathableMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo protocols: [TypeSyntax],
    in context: C
  ) throws -> [ExtensionDeclSyntax] {
    // if protocols.isEmpty {
    //   return []
    // }
    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      // TODO: Diagnostic?
      return []
    }
    if let inheritanceClause = enumDecl.inheritanceClause,
       inheritanceClause.inheritedTypes.contains(
        where: { Self.conformanceNames.contains($0.type.trimmedDescription) }
       )
    {
      return []
    }
    
    // Inhibit if @CasePathabler is present, @Composer will issue diagnostic
    guard !enumDecl.attributes.hasMacroApplication("CasePathable") else {
      return []
    }
    
    let ext: DeclSyntax =
      """
      extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
      """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension _ComposerCasePathableMacro: MemberMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax, Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self)
    else {
      throw DiagnosticsError(
        diagnostics: [
          CasePathableMacroDiagnostic
            .notAnEnum(declaration)
            .diagnose(at: declaration.keyword)
        ]
      )
    }
    
    // Inhibit if @CasePathabler is present, @Composer will issue diagnostic
    guard !enumDecl.attributes.hasMacroApplication("CasePathable") else {
      return []
    }
    
    let visitor = AllCaseNamesVisitor(viewMode: .all)
    visitor.walk(declaration)
    
    var decls = [DeclSyntax]()
    
    let access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)
    
    if !visitor.hasGeneratableCasePaths {
      let enumName = enumDecl.name.trimmed
      let rewriter = SelfRewriter(selfEquivalent: enumName)
      let memberBlock = rewriter.rewrite(enumDecl.memberBlock).cast(MemberBlockSyntax.self)
      
      let enumCaseDecls = memberBlock
        .members
        .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }
      
      var seenCaseNames: Set<String> = []
      for enumCaseDecl in enumCaseDecls {
        let name = enumCaseDecl.name.text
        if seenCaseNames.contains(name) {
          throw DiagnosticsError(
            diagnostics: [
              CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(
                at: Syntax(enumCaseDecl.name))
            ]
          )
        }
        seenCaseNames.insert(name)
      }
      
      let casePaths = generateDeclSyntax(from: memberBlock.members, with: access, enumName: enumName)
      decls.append(
          """
          \(access)struct \(raw: allCasePathsTypeName) {
          \(raw: casePaths.map(\.description).joined(separator: "\n"))
          }
          """)
    }
    
    decls.append(
        """
        \(access)static var allCasePaths: \(raw: allCasePathsTypeName) { \(raw: allCasePathsTypeName)() }
        """
    )
    
    return decls
  }
  
  static func generateDeclSyntax(
    from elements: MemberBlockItemListSyntax,
    with access: DeclModifierListSyntax.Element?,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    elements.flatMap {
      if let elements = $0.decl.as(EnumCaseDeclSyntax.self)?.elements {
        return generateDeclSyntax(from: elements, with: access, enumName: enumName)
      }
      if let ifConfigDecl = $0.decl.as(IfConfigDeclSyntax.self) {
        let ifClauses = ifConfigDecl.clauses.flatMap { decl -> [DeclSyntax] in
          guard let elements = decl.elements?.as(MemberBlockItemListSyntax.self) else {
            return []
          }
          let title = "\(decl.poundKeyword.text) \(decl.condition?.description ?? "")"
          return ["\(raw: title)"]
          + generateDeclSyntax(from: elements, with: access, enumName: enumName)
        }
        return ifClauses + ["#endif"]
      }
      return []
    }
  }
  
  static func generateAttributeSyntax(
    from enumCaseDecls: EnumCaseElementListSyntax,
    with access: DeclModifierListSyntax.Element?,
    enumName: TokenSyntax
  ) -> [AttributeSyntax] {
    enumCaseDecls.map {
      let caseName = $0.name.trimmed
      let associatedValueType = $0.trimmedTypeDescription
      
      return """
            @_ComposedCasePathMember(enumName: "\(raw: enumName)", caseName: "\(raw: caseName)", of: \(raw: associatedValueType).self)
        """
    }
  }
  
  
  static func generateDeclSyntax(
    from enumCaseDecls: EnumCaseElementListSyntax,
    with access: DeclModifierListSyntax.Element?,
    enumName: TokenSyntax
  ) -> [DeclSyntax] {
    enumCaseDecls.map {
      let caseName = $0.name.trimmed
      let associatedValueName = $0.trimmedTypeDescription
      let hasPayload = $0.parameterClause.map { !$0.parameters.isEmpty } ?? false
      let bindingNames: String
      let returnName: String
      if hasPayload, let associatedValue = $0.parameterClause {
        let parameterNames = (0..<associatedValue.parameters.count)
          .map { "v\($0)" }
          .joined(separator: ", ")
        bindingNames = "(\(parameterNames))"
        returnName = associatedValue.parameters.count == 1 ? parameterNames : bindingNames
      } else {
        bindingNames = ""
        returnName = "()"
      }
      
      return """
        \(access)var \(caseName): \
        \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)> {
        \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)>(
        embed: \(raw: hasPayload ? "\(enumName).\(caseName)" : "{ \(enumName).\(caseName) }"),
        extract: {
        guard case\(raw: hasPayload ? " let" : "").\(caseName)\(raw: bindingNames) = $0 else { \
        return nil \
        }
        return \(raw: returnName)
        }
        )
        }
        """
    }
  }
}

extension _ComposerCasePathableMacro: MemberAttributeMacro {
  
  public static func expansion<
    Declartion: DeclGroupSyntax,
    Member: DeclSyntaxProtocol,
    Context: MacroExpansionContext
  >(of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: Declartion,
    providingAttributesFor member: Member,
    in context: Context) throws -> [SwiftSyntax.AttributeSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      return []
    }
    
    let access = enumDecl.modifiers.first(where: \.isNeededAccessLevelModifier)
    
    if let structDecl = member.as(StructDeclSyntax.self) {
      guard structDecl.name.text == allCasePathsTypeName else {
        // TODO Diagnostic
        return []
      }
      
      let enumName = enumDecl.name.trimmed
      let rewriter = SelfRewriter(selfEquivalent: enumName)
      let memberBlock = rewriter.rewrite(enumDecl.memberBlock).cast(MemberBlockSyntax.self)
      
      let enumCaseDecls = memberBlock
        .members
        .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }
      
      var seenCaseNames: Set<String> = []
      for enumCaseDecl in enumCaseDecls {
        let name = enumCaseDecl.name.text
        if seenCaseNames.contains(name) {
          throw DiagnosticsError(
            diagnostics: [
              CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(
                at: Syntax(enumCaseDecl.name))
            ]
          )
        }
        seenCaseNames.insert(name)
      }
      
      let result = memberBlock.members.flatMap {
        if let elements = $0.decl.as(EnumCaseDeclSyntax.self)?.elements {
          return  generateAttributeSyntax(from: elements, with: access, enumName: enumName)
        }
        return []
      }
      return result
    }
    else {
      return []
    }
  }
}

enum CasePathableMacroDiagnostic {
  case notAnEnum(DeclGroupSyntax)
  case overloadedCaseName(String)
}

extension CasePathableMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case let .notAnEnum(decl):
      return """
        '@CasePathable' cannot be applied to\
        \(decl.keywordDescription.map { " \($0)" } ?? "") type\
        \(decl.nameDescription.map { " '\($0)'" } ?? "")
        """
    case let .overloadedCaseName(name):
      return """
        '@CasePathable' cannot be applied to overloaded case name '\(name)'
        """
    }
  }
  
  var diagnosticID: MessageID {
    switch self {
    case .notAnEnum:
      return MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
    case .overloadedCaseName:
      return MessageID(domain: "MetaEnumDiagnostic", id: "overloadedCaseName")
    }
  }
  
  var severity: DiagnosticSeverity {
    switch self {
    case .notAnEnum:
      return .error
    case .overloadedCaseName:
      return .error
    }
  }
  
  func diagnose(at node: Syntax) -> Diagnostic {
    Diagnostic(node: node, message: self)
  }
}

extension DeclGroupSyntax {
  var keyword: Syntax {
    switch self {
    case let syntax as ActorDeclSyntax:
      return Syntax(syntax.actorKeyword)
    case let syntax as ClassDeclSyntax:
      return Syntax(syntax.classKeyword)
    case let syntax as ExtensionDeclSyntax:
      return Syntax(syntax.extensionKeyword)
    case let syntax as ProtocolDeclSyntax:
      return Syntax(syntax.protocolKeyword)
    case let syntax as StructDeclSyntax:
      return Syntax(syntax.structKeyword)
    case let syntax as EnumDeclSyntax:
      return Syntax(syntax.enumKeyword)
    default:
      return Syntax(self)
    }
  }
  
  var keywordDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.actorKeyword.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.classKeyword.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extensionKeyword.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.protocolKeyword.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.structKeyword.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.enumKeyword.trimmedDescription
    default:
      return nil
    }
  }
  
  var nameDescription: String? {
    switch self {
    case let syntax as ActorDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ClassDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as ExtensionDeclSyntax:
      return syntax.extendedType.trimmedDescription
    case let syntax as ProtocolDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as StructDeclSyntax:
      return syntax.name.trimmedDescription
    case let syntax as EnumDeclSyntax:
      return syntax.name.trimmedDescription
    default:
      return nil
    }
  }
}

extension DeclModifierSyntax {
  var isNeededAccessLevelModifier: Bool {
    switch self.name.tokenKind {
    case .keyword(.public): return true
    case .keyword(.package): return true
    default: return false
    }
  }
}

extension EnumCaseElementListSyntax.Element {
  var trimmedTypeDescription: String {
    if var associatedValue = self.parameterClause, !associatedValue.parameters.isEmpty {
      if associatedValue.parameters.count == 1,
         let type = associatedValue.parameters.first?.type.trimmed
      {
        return type.is(SomeOrAnyTypeSyntax.self)
        ? "(\(type))"
        : "\(type)"
      } else {
        for index in associatedValue.parameters.indices {
          associatedValue.parameters[index].type.trailingTrivia = ""
          associatedValue.parameters[index].defaultValue = nil
          if associatedValue.parameters[index].firstName?.tokenKind == .wildcard {
            associatedValue.parameters[index].colon = nil
            associatedValue.parameters[index].firstName = nil
            associatedValue.parameters[index].secondName = nil
          }
        }
        return "(\(associatedValue.parameters.trimmed))"
      }
    } else {
      return "Void"
    }
  }
}

extension SyntaxStringInterpolation {
  mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
    if let node {
      self.appendInterpolation(node)
    }
  }
}

final class SelfRewriter: SyntaxRewriter {
  let selfEquivalent: TokenSyntax
  
  init(selfEquivalent: TokenSyntax) {
    self.selfEquivalent = selfEquivalent
  }
  
  override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    guard node.name.text == "Self"
    else { return super.visit(node) }
    return super.visit(node.with(\.name, self.selfEquivalent))
  }
}

final class AllCaseNamesVisitor: SyntaxVisitor {
  
  var allCasePathsDecl: StructDeclSyntax?
  
  var hasAllCasePathsDecl: Bool {
    return allCasePathsDecl != nil
  }
  
  var hasGeneratableCasePaths: Bool {
    allCasePathsDecl?.attributes.hasMacro("ComposeAllCasePaths") ?? false
  }
  
  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    if (node.name.text == _ComposerCasePathableMacro.allCasePathsTypeName) {
      allCasePathsDecl = node
    }
    return .skipChildren
  }
}

extension AttributeListSyntax {
  
  func hasMacro(_ name: String) -> Bool {
    for attribute in self {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return true
        }
      default:
        break
      }
    }
    return false
  }
}

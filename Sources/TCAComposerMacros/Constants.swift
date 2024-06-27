import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

enum CasePathConstants {
  static let casePathsModuleName = "CasePaths"
  static let casePathableConformanceName = "CasePathable"
  static var qualifiedConformanceName: String { "\(Self.casePathsModuleName).\(Self.casePathableConformanceName)" }
  static var conformanceNames: [String] { [Self.casePathableConformanceName, Self.qualifiedConformanceName] }
}

enum MacroNames {
  
  static let composeActionCase = "ComposeActionCase"
  static let composeActionAlertCase = "ComposeActionAlertCase"
  static let composeActionConfirmationDialogCase = "ComposeActionConfirmationDialogCase"
  
  static let composeBody = "ComposeBody"
  static let composeBodyChildReducer = "ComposeBodyChildReducer"
  static let composeBodyActionAlertCase = "ComposeBodyActionAlertCase"
  static let composeBodyActionConfirmationDialogCase = "ComposeBodyActionConfirmationDialogCase"
  static let composeBodyActionCase = "ComposeBodyActionCase"
  static let composeBodyOnChange = "ComposeBodyOnChange"

  static let composeReducer = "ComposeReducer"
  static let composeEnumReducer = "ComposeEnumReducer"

  static let composeScopePath = "ComposeScopePath"

  static let allComposeDirectiveMacros = [
    composeActionCase,
    composeActionAlertCase,
    composeActionConfirmationDialogCase,
    
    composeBody,
    composeBodyChildReducer,
    composeBodyActionAlertCase,
    composeBodyActionConfirmationDialogCase,
    composeBodyActionCase,
    composeBodyOnChange,

    composeReducer,
    composeEnumReducer,

    composeScopePath,
  ]

  static let enumComposeDirectiveMacros = [
    composeActionCase,
    composeActionAlertCase,
    composeActionConfirmationDialogCase,
  ]

  static let functionComposeDirectiveMacros = [
    composeBody,
    composeBodyChildReducer,
    composeBodyActionAlertCase,
    composeBodyActionConfirmationDialogCase,
    composeBodyActionCase,
    composeBodyOnChange,
  ]

  static let structComposeDirectiveMacros = [
    composeReducer,
    composeEnumReducer,
  ]

  static let variableComposeDirectiveMacros = [
    composeScopePath
  ]

}

enum Identifiers {

  static var forEach: TokenSyntax { .identifier("forEach") }
  static var ifCaseLet: TokenSyntax { .identifier("ifCaseLet") }
  static var ifLet: TokenSyntax { .identifier("ifLet") }
  static var onChange: TokenSyntax { .identifier("onChange") }

  static var Action: TokenSyntax { .identifier("Action") }
  static var State: TokenSyntax { .identifier("State") }

  // TODO: Convert these to correct syntax for correctness
  // NB: Technically these are not proper identifiers and should be created as member access expressions
  // but the compiler doesn't seem to care and emits the correct code, and this is easier to construct.
  static var BindingReducer: TokenSyntax { .identifier("ComposableArchitecture.BindingReducer") }
  static var ComposeReducers: TokenSyntax { .identifier("ComposableArchitecture.CombineReducers") }
  static var EmptyReducer: TokenSyntax { .identifier("ComposableArchitecture.EmptyReducer") }
  static var Reduce: TokenSyntax { .identifier("ComposableArchitecture.Reduce") }
  static var ReduceAction: TokenSyntax { .identifier("TCAComposer.ReduceAction") }
  static var ReduceIdentifiedAction: TokenSyntax {
    .identifier("TCAComposer.ReduceIdentifiedAction")
  }
  static var Scope: TokenSyntax { .identifier("ComposableArchitecture.Scope") }

}

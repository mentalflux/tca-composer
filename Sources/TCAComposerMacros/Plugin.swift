import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    // User macros
    ComposeDirectiveMacro.self,
    ComposerMacro.self,

    // Internal macros
    _ComposedActionMacro.self,
    _ComposerCasePathableActions.self,
    _ComposerScopeSwitchableMacro.self,
    _ComposerScopePathableMacro.self,
    _ComposedStateMemberMacro.self,

    // CasePathable Support Macros
    _ComposedCasePathMemberMacro.self,
    _ComposedActionMemberMacro.self,
    _ComposerCasePathableMacro.self
  ]
}

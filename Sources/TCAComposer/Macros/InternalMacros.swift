import ComposableArchitecture

@attached(extension, conformances: CasePaths.CasePathable)
@attached(member, names: named(AllCasePaths), named(allCasePaths))
@attached(memberAttribute)
public macro _ComposerCasePathable() =
#externalMacro(
  module: "TCAComposerMacros", type: "_ComposerCasePathableMacro"
)

@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro _ComposedActionMember<T>(_ name: String, of: T.Type) =
#externalMacro(
  module: "TCAComposerMacros", type: "_ComposedActionMemberMacro"
)

@attached(member, names: arbitrary)
public macro _ComposedCasePathMember<T>(enumName: String, caseName: String, of: T.Type) =
#externalMacro(
  module: "TCAComposerMacros", type: "_ComposedCasePathMemberMacro"
)

@attached(extension, conformances: ScopePathable)
@attached(member, names: named(allComposedScopePaths))
public macro _ComposerScopePathable() =
  #externalMacro(module: "TCAComposerMacros", type: "_ComposerScopePathableMacro")

@attached(extension, conformances: ScopeSwitchable)
@attached(member, names: named(allComposedScopeCases))
public macro _ComposerScopeSwitchable() =
  #externalMacro(module: "TCAComposerMacros", type: "_ComposerScopeSwitchableMacro")

public enum _ComposedStateMemberOption {
  case presents
}

@attached(member, names: arbitrary)
public macro _ComposedStateMember<T>(
  _ name: String, of reducerType: T.Type, options: _ComposedStateMemberOption... = []
) =
  #externalMacro(
    module: "TCAComposerMacros", type: "_ComposedStateMemberMacro"
  )

@attached(member, names: arbitrary)
public macro _ComposedStateMember<T>(
  _ name: String, of reducerType: T.Type, initialValue: @autoclosure () -> T,
  options: _ComposedStateMemberOption... = []
) =
  #externalMacro(
    module: "TCAComposerMacros", type: "_ComposedStateMemberMacro"
  )

public enum _ComposedActionOption {
  case bindableAction
  case viewAction
}

@attached(
  extension, conformances: ComposableArchitecture.BindableAction, ComposableArchitecture.ViewAction)
public macro _ComposedAction(_ options: _ComposedActionOption...) =
  #externalMacro(module: "TCAComposerMacros", type: "_ComposedActionMacro")

@attached(memberAttribute)
public macro _ComposerCasePathableActions() =
  #externalMacro(module: "TCAComposerMacros", type: "_ComposerCasePathableActions")

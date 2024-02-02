import SwiftSyntax

extension String {

  func lowerFirst() -> String {
    return self.prefix(1).lowercased() + self.dropFirst()
  }

  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else { return self }
    return String(self.dropFirst(prefix.count))
  }

  func deletingSuffix(_ suffix: String) -> String {
    guard self.hasSuffix(suffix) else { return self }
    return String(self.dropLast(suffix.count))
  }
}

extension String {

  func scopedWith(_ scopes: [String]) -> String {
    return [scopes, [self]].flatMap { $0 }.joined(separator: ".")
  }
}

extension AttributeSyntax {

  func matches(_ names: [String]) -> Bool {
    let name = self.attributeName.trimmedDescription
    return names.contains(where: { $0 == name })
  }
}

extension AttributeListSyntax {

  func hasMacroApplication(_ name: String) -> Bool {
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

  func firstAttribute(for name: String) -> AttributeSyntax? {
    for attribute in self {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          return attr
        }
      default:
        break
      }
    }
    return nil
  }

  func allAttributes(for name: String) -> [AttributeSyntax] {
    var matches = [AttributeSyntax]()
    for attribute in self {
      switch attribute {
      case .attribute(let attr):
        if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)] {
          matches.append(attr)
        }
      default:
        break
      }
    }
    return matches
  }

  func allAttributes(matching names: [String]) -> [AttributeSyntax] {
    var matches = [AttributeSyntax]()
    for attribute in self {
      switch attribute {
      case .attribute(let attr):
        if names.contains(attr.attributeName.trimmedDescription) {
          matches.append(attr)
        }
      default:
        break
      }
    }
    return matches
  }
}

extension KeyPathExprSyntax {

  init(keyPath: String) {
    var components = KeyPathComponentListSyntax()

    let stripped = keyPath.deletingPrefix("\\")

    var period: TokenSyntax? = stripped.starts(with: ".") ? .periodToken() : nil

    let stringComponents = stripped.split(separator: ".")

    for (index, element) in stringComponents.enumerated() {
      if index > 0 && period == nil {
        period = .periodToken()
      }

      let property = KeyPathPropertyComponentSyntax(
        declName: DeclReferenceExprSyntax(
          baseName: .identifier(String(element))
        ))

      let component = KeyPathComponentSyntax(period: period, component: .property(property))

      components.append(
        component
      )
    }
    self.init(components: components)
  }
}

// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "tca-composer",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(name: "TCAComposer", targets: ["TCAComposer"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "1.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.7.0"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.2.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.1.0"),
  ],
  targets: [
    .target(
      name: "TCAComposer",
      dependencies: [
        "TCAComposerMacros",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "TCAComposerTests",
      dependencies: [
        "TCAComposer"
      ]
    ),
    .macro(
      name: "TCAComposerMacros",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
      ]
    ),
    .testTarget(
      name: "TCAComposerMacroTests",
      dependencies: [
        "TCAComposerMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    ),
  ]
)

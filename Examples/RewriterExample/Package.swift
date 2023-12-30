// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-public-rewriter-example",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "MyModule", targets: ["MyModule"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2"),
      .package(name: "swift-public-rewriter", path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "main",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "PublicRewriter", package: "swift-public-rewriter"),
            ]
        ),
        .target(name: "MyModule"),
    ]
)

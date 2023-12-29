// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-public-rewriter",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "PublicRewriter", targets: ["PublicRewriter"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2"),
    ],
    targets: [
        .executableTarget(
            name: "main",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                "PublicRewriter",
            ]
        ),
        .target(name: "MyModule"),
        .target(
            name: "PublicRewriter",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "PublicRewriterTests",
            dependencies: [
                "PublicRewriter",
            ]
        ),
    ]
)

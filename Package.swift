// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-public-rewriter",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "Rewriter", targets: ["Rewriter"]),
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
                "Rewriter",
            ]
        ),
        .target(name: "MyModule"),
        .target(
            name: "Rewriter",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "RewriterTests",
            dependencies: [
                "Rewriter",
            ]
        ),
    ]
)

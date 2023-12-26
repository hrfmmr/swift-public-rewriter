// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swiftsyntax-sandbox",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "MyModule", targets: ["MyModule"]),
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
                "MyModule",
            ]
        ),
        .target(name: "MyModule"),
    ]
)

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-public-rewriter",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .publicRewriterCLI,
        .publicRewriterCore,
    ],
    dependencies: [
        .swiftSyntax,
        .swiftArgumentParser,
    ],
    targets: [
        .publicRewriterCLI,
        .publicRewriterCore,
        .publicRewriterTests,
    ]
)

private extension PackageDescription.Product {
    typealias _Self = PackageDescription.Product
    static let publicRewriterCLI: _Self = .executable(
        name: .LocalTarget.CLI.productName,
        targets: [.LocalTarget.CLI.targetName]
    )

    static let publicRewriterCore: _Self = .library(
        name: .LocalTarget.publicRewriterCore,
        targets: [.LocalTarget.publicRewriterCore]
    )
}

private extension PackageDescription.Package.Dependency {
    typealias _Self = PackageDescription.Package.Dependency
    static let swiftSyntax: _Self = .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
    static let swiftArgumentParser: _Self =  .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
}

private extension PackageDescription.Target {
    typealias _Self = PackageDescription.Target
    static let publicRewriterCLI: _Self = .executableTarget(
        name: .LocalTarget.CLI.targetName,
        dependencies: [
            .publicRewriterCore,
            .swiftSyntax,
            .swiftSyntaxBuilder,
            .swiftArgumentParser,
        ]
    )
    static let publicRewriterCore: _Self = .target(
        name: .LocalTarget.publicRewriterCore,
        dependencies: [
            .swiftSyntax,
            .swiftSyntaxBuilder,
        ]
    )
    static let publicRewriterTests: _Self = .testTarget(
        name: .LocalTarget.publicRewriterTests,
        dependencies: [.publicRewriterCore]
    )

}

private extension PackageDescription.Target.Dependency {
    // Third party libs
    static let swiftSyntax: Self = .product(name: "SwiftSyntax", package: "swift-syntax")
    static let swiftSyntaxBuilder: Self = .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
    static let swiftArgumentParser: Self = .product(name: "ArgumentParser", package: "swift-argument-parser")
    
    // Local targets
    static let publicRewriterCore: Self = .target(name: .LocalTarget.publicRewriterCore)
}

private extension String {
    enum LocalTarget {
        enum CLI {
            static let productName = "swift-public-rewriter"
            static let targetName = "PublicRewriterCLI"
        }
        static let publicRewriterCore = "PublicRewriterCore"
        static let publicRewriterTests = "PublicRewriterTests"
    }
}

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-public-rewriter",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15),
    ],
    products: [
        .publicRewriter,
    ],
    dependencies: [
        .swiftSyntax
    ],
    targets: [
        .publicRewriter,
        .publicRewriterTests,
    ]
)

private extension PackageDescription.Package.Dependency {
    typealias _Self = PackageDescription.Package.Dependency
    static let swiftSyntax: _Self = .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.2")
}

private extension PackageDescription.Product {
    typealias _Self = PackageDescription.Product
    static let publicRewriter: _Self = .library(
        name: .LocalTarget.publicRewriter,
        targets: [.LocalTarget.publicRewriter]
    )
}

private extension PackageDescription.Target {
    typealias _Self = PackageDescription.Target
    static let publicRewriter: _Self = .target(
        name: .LocalTarget.publicRewriter,
        dependencies: [
            .swiftSyntax,
            .swiftSyntaxBuilder,
        ]
    )
    static let publicRewriterTests: _Self = .testTarget(
        name: .LocalTarget.publicRewriterTests,
        dependencies: [.publicRewriter]
    )

}

private extension PackageDescription.Target.Dependency {
    // Third party libs
    static let swiftSyntax: Self = .product(name: "SwiftSyntax", package: "swift-syntax")
    static let swiftSyntaxBuilder: Self = .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
    
    // Local targets
    static let publicRewriter: Self = .target(name: .LocalTarget.publicRewriter)
}

private extension String {
    enum LocalTarget {
        static let publicRewriter = "PublicRewriter"
        static let publicRewriterTests = "PublicRewriterTests"
    }
}

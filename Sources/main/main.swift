import Foundation

import SwiftSyntax
import SwiftParser

private extension VariableDeclSyntax {
    /// Whether `private(set) var ...`
    var hasPrivateSet: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "private", let detail = modifier.detail, detail.detail.text == "set"
        else { return false }
        return true
    }
}

class PublicModifierRewriter: SyntaxRewriter {
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard let parent = node.parent, parent.is(MemberBlockItemSyntax.self)
        else { return super.visit(node) }
        
        if node.hasPrivateSet == false || node.modifiers.isEmpty {
            return super.visit(node)
        }
        print("🟠node(VariableDeclSyntax):\(node.description)")
        
        guard case let .keyword(keyword) = node.bindingSpecifier.tokenKind else { return super.visit(node) }

        let newModifiers: DeclModifierListSyntax = {
            let publicModifier = DeclModifierSyntax(
                leadingTrivia: .newlines(1),
                name: .keyword(.public),
                trailingTrivia: .spaces(1)
            )
            var modifiers = DeclModifierListSyntax([
                publicModifier
            ])
            if node.hasPrivateSet {
                let existingModifier = DeclModifierSyntax(
                    name: .keyword(.private),
                    trailingTrivia: .spaces(1)
                )
                modifiers.append(existingModifier.with(\.detail, Array(node.modifiers)[0].detail))
            }
            return modifiers
        }()
        
        let newNode = node.with(
            \.bindingSpecifier,
             .keyword(keyword, trailingTrivia: .spaces(1))
        )
            .with(\.modifiers, newModifiers)
        return super.visit(newNode)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🟣node(ClassDeclSyntax):\(node.name)")
        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newModifiers = DeclModifierListSyntax([
            DeclModifierSyntax(
                leadingTrivia: .newlines(2),
                name: .keyword(.public),
                trailingTrivia: .spaces(1)
            )
        ])
        let newNode = node.with(
            \.classKeyword,
             .keyword(.class, trailingTrivia: .spaces(1))
        )
            .with(\.modifiers, newModifiers)
        return super.visit(DeclSyntax(newNode))
    }
}

func makeClassPublic(in source: String) throws -> String {
    let sourceFile = Parser.parse(source: source)
    let rewriter = PublicModifierRewriter()
    let modifiedSourceFile = rewriter.visit(sourceFile)
    return modifiedSourceFile.description
}

func main() {
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    print("current directory:\(currentDirectoryURL)")


    let directoryURL = URL(fileURLWithPath: "./")
    let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil)

    while let url = enumerator?.nextObject() as? URL {
        guard url.pathExtension == "swift" else { continue }
        
        guard url.pathComponents.contains("MyModule") else { continue }
        print("🔄 modify src:\(url)")

        let sourceCode = try! String(contentsOf: url, encoding: .utf8)
        let modifiedCode = try! makeClassPublic(in: sourceCode)
        try! modifiedCode.write(to: url, atomically: true, encoding: .utf8)
    }
}

main()

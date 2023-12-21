// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

class PublicModifierRewriter: SyntaxRewriter {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        print("🟣node(ClassDeclSyntax):\(node.name)")
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        let newModifiers = DeclModifierListSyntax([
            DeclModifierSyntax(leadingTrivia: .newlines(2), name: .keyword(.public), trailingTrivia: .spaces(1))
        ])
        return super.visit(DeclSyntax(node.with(\.modifiers, newModifiers)))
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

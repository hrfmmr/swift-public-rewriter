// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

class PublicModifierRewriter: SyntaxRewriter {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        print("🟣node:\(node.name)")
        let newModifiers = DeclModifierListSyntax([
            DeclModifierSyntax(leadingTrivia: .newlines(1), name: .keyword(.public), trailingTrivia: .spaces(1))
        ])
        return DeclSyntax(node.with(\.modifiers, newModifiers))
//        return super.visit(node.with(\.modifiers, newModifiers).cast(DeclSyntax.self))
//        return super.visit(node)
        
//        super.visit(node)
//        return node.with(\.modifiers, newModifiers).cast(DeclSyntax.self)
        
//        return visit(node.with(\.modifiers, newModifiers).cast(DeclSyntax.self))
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

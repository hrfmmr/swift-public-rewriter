import Foundation
import ArgumentParser

import SwiftSyntax
import SwiftParser

import PublicRewriterCore

@main
struct PublicRewriter: ParsableCommand {
    @Argument(help: "The path to the source directory or file that will be rewritten.", completion: .directory)
    var targetPath: URL

    mutating func run() throws {
        let enumerator = FileManager.default.enumerator(at: targetPath, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            print("🔄 modify src:\(url)")
            let source = try String(contentsOf: url, encoding: .utf8)
            let modifiedSource = makePublic(in: source)
            try modifiedSource.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

private func makePublic(in source: String) -> String {
    let sourceFile = Parser.parse(source: source)
    let rewriter = PublicModifierRewriter()
    let modified = rewriter.visit(sourceFile)
    return modified.description
}

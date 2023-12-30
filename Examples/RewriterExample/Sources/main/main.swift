import Foundation

import SwiftSyntax
import SwiftParser

import PublicRewriter

func makePublic(in source: String) throws -> String {
    let sourceFile = Parser.parse(source: source)
    let rewriter = PublicModifierRewriter()
    let modifiedSourceFile = rewriter.visit(sourceFile)
    return modifiedSourceFile.description
}

func main() throws {
    let currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    print("current directory:\(currentDirectoryURL)")

    let directoryURL = URL(fileURLWithPath: "./")
    let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil)

    while let url = enumerator?.nextObject() as? URL {
        guard url.pathExtension == "swift" else { continue }
        
        guard url.pathComponents.contains("MyModule") else { continue }
        print("🔄 modify src:\(url)")

        let sourceCode = try String(contentsOf: url, encoding: .utf8)
        let modifiedCode = try makePublic(in: sourceCode)
        try modifiedCode.write(to: url, atomically: true, encoding: .utf8)
    }
}

do {
   try main()
} catch {
   print("❗error:\(error)")
}

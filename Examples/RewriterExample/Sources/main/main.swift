import Foundation

import SwiftSyntax
import SwiftParser

import PublicRewriterCore

private func makePublic(for fileURL: URL) throws {
    guard fileURL.pathExtension == "swift" else { return }
    print("🔄Modify src:\(fileURL)")
    let source = try String(contentsOf: fileURL, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)
    let rewriter = PublicModifierRewriter()
    let modified = rewriter.visit(sourceFile)
    try modified.description.write(to: fileURL, atomically: true, encoding: .utf8)
}

private func main() throws {
    let directoryURL = URL(fileURLWithPath: "./Sources/MyModule")
    let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil)
    while let url = enumerator?.nextObject() as? URL {
        try makePublic(for: url)
    }
}

do {
   try main()
} catch {
   print("❗error:\(error)")
}

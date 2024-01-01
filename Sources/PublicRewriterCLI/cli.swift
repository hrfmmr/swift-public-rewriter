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
        switch try targetPath.isDirectory {
        case false:
            try makePublic(for: targetPath)
        case true:
            let enumerator = FileManager.default.enumerator(at: targetPath, includingPropertiesForKeys: nil)
            while let url = enumerator?.nextObject() as? URL {
                try makePublic(for: url)
            }
        }
        print("✔Done")
    }
}

extension PublicRewriter {
    enum Error: Swift.Error, LocalizedError {
        case targetPathNotFound(URL)
        
        var errorDescription: String? {
            switch self {
            case let .targetPathNotFound(url):
                return "Cannot access `\(url)`: No such file or directory"
            }
        }
    }
}

private func makePublic(for fileURL: URL) throws {
    guard fileURL.pathExtension == "swift" else { return }
    print("🔄Modify src:\(fileURL)")
    let source = try String(contentsOf: fileURL, encoding: .utf8)
    let sourceFile = Parser.parse(source: source)
    let rewriter = PublicModifierRewriter()
    let modified = rewriter.visit(sourceFile)
    try modified.description.write(to: fileURL, atomically: true, encoding: .utf8)
}

private extension URL {
    var isDirectory: Bool {
        get throws {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory)
            else { throw PublicRewriter.Error.targetPathNotFound(self) }
            return isDirectory.boolValue
        }
    }
}

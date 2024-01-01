import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriterCore

class EnumDeclSyntaxTests: XCTestCase {
    func testRewriter() throws {
        let source = """
enum Test {
    case a, b, c
    var string: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        }
    }
    
    func makeString() -> String {
        string
    }
}
"""
        let expected = """
public enum Test {
    case a, b, c
    public var string: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        }
    }
    
    public func makeString() -> String {
        string
    }
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

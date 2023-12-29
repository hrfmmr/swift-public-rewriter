import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriter

class FunctionDeclSyntaxTests: XCTestCase {
    func testRewriter() throws {
        let source = """
private func privateFunc() {}

func internalFunc() {}

public func publicFunc() {}
"""
        let expected = """
private func privateFunc() {}

public func internalFunc() {}

public func publicFunc() {}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

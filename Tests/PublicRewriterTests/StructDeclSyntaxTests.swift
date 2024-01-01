import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriterCore

class StructDeclSyntaxTests: XCTestCase {
    func testRewriter() throws {
        let source = """
struct Test {
    let x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    func doSomething() {
        let _ = ""
        var _ = 0
    }

    mutating func updateY(_ y: Int) {
        self.y = y
    }

    static func from(x: Int) -> Self {
        .init(x: x, y: 0)
    }
}
"""
        let expected = """
public struct Test {
    public let x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func doSomething() {
        let _ = ""
        var _ = 0
    }

    public mutating func updateY(_ y: Int) {
        self.y = y
    }

    public static func from(x: Int) -> Self {
        .init(x: x, y: 0)
    }
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

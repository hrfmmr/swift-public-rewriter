import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriterCore

class VariableDeclSyntaxTests: XCTestCase {
    func testRewriter() throws {
        let source = """
class Test {
    let x: Int = 0
    var y: Int?
    private (set) var z: String?
    lazy var lz: String = {
        "lazy"
    }()

    func doSomething() {
        let _ = ""
        var _ = 0
    }

    class Inner {
        let x: Int = 0
        var y: Int?
        private (set) var z: String?
        lazy var lz: String = {
            "lazy"
        }()
    }
}
"""
        let expected = """
public class Test {
    public let x: Int = 0
    public var y: Int?
    public private (set) var z: String?
    public lazy var lz: String = {
        "lazy"
    }()

    public func doSomething() {
        let _ = ""
        var _ = 0
    }

    public class Inner {
        public let x: Int = 0
        public var y: Int?
        public private (set) var z: String?
        public lazy var lz: String = {
            "lazy"
        }()
    }
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

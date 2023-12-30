import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriter

class ClassDeclSyntaxTests: XCTestCase {
    func testRewriter() throws {
        let source = """
open class OpenClass {
    open func doSomething() {}
}

class InheritedClass: OpenClass {
    let x: Int = 0
    var y: Int?
    private (set) var z: String?
    lazy var lz: String = {
        "lazy"
    }()
    override init() {
        super.init()
    }
    override func doSomething() {
        let _ = ""
        var _ = 0
    }
    
    class Inner {
        let x: Int = 0
    }
}
"""
        let expected = """
open class OpenClass {
    open func doSomething() {}
}

public class InheritedClass: OpenClass {
    public let x: Int = 0
    public var y: Int?
    public private (set) var z: String?
    public lazy var lz: String = {
        "lazy"
    }()
    public override init() {
        super.init()
    }
    public override func doSomething() {
        let _ = ""
        var _ = 0
    }
    
    public class Inner {
        public let x: Int = 0
    }
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

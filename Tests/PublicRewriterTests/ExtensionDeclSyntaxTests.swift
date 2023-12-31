import XCTest

import SwiftSyntax
import SwiftParser

@testable import PublicRewriterCore

class ExtensionDeclSyntaxTests: XCTestCase {
    func testRewriter_withoutInheritanceClause() throws {
        let source = """
private extension ExampleStruct {
    struct InnerPrivateExampleStruct {}
    enum InnerPrivateExampleEnum {}
    class InnerPrivateExampleClass {}
}

extension ExampleStruct {
    struct InnerExampleStruct {}
    enum InnerExampleEnum {}
    class InnerExampleClass {}
}

public struct ExamplePublicStruct {}

public extension ExamplePublicStruct {
    struct InnerPublicExampleStrut {}
    enum InnerPublicExampleEnum {}
    class InnerPublicExampleClass {}
}
"""
        let expected = """
private extension ExampleStruct {
    struct InnerPrivateExampleStruct {}
    enum InnerPrivateExampleEnum {}
    class InnerPrivateExampleClass {}
}

public extension ExampleStruct {
    struct InnerExampleStruct {}
    enum InnerExampleEnum {}
    class InnerExampleClass {}
}

public struct ExamplePublicStruct {}

public extension ExamplePublicStruct {
    struct InnerPublicExampleStrut {}
    enum InnerPublicExampleEnum {}
    class InnerPublicExampleClass {}
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }

    func testRewriter_withInheritanceClause() throws {
        let source = """
protocol TestProtocol {
    var x: Int { get }
    func test()
}

struct Foo {}

extension Foo: TestProtocol {
    var x: Int { 0 }
    func test() {}
}
"""
        let expected = """
public protocol TestProtocol {
    var x: Int { get }
    func test()
}

public struct Foo {}

extension Foo: TestProtocol {
    public var x: Int { 0 }
    public func test() {}
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = PublicModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
    }
}

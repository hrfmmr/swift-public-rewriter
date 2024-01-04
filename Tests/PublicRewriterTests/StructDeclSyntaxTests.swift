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
    
    func testGenerateInitializer() throws {
        let source = """
struct Test {
    let x: Int
"""
        
        let expected = """
struct Test {
    let x: Int
    init(x: Int) {
        self.x = x
    }
}
"""
        
        let sourceFile = Parser.parse(source: source)
        let rewriter = _ModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        print("=====================")
        print(modifiedSource.description)
        print("=====================")
//        XCTAssertEqual(modifiedSource.description, expected)
    }
}

private extension StructDeclSyntaxTests {
    class _ModifierRewriter: SyntaxRewriter {
        override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
            var newNode = node
            if let modified = node.initializerBlockAppended() {
                newNode = modified
            }
            return super.visit(newNode)
        }
    }
}

private extension StructDeclSyntax {
    func initializerBlockAppended() -> Self? {
        let members = Array(memberBlock.members)
        guard members.isEmpty == false else { return nil }
        let initializeVariables = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter {
                guard
                    $0.bindings.count == 1,
                    $0.isOptionalDecl == false,
                    $0.hasInitializerDecl == false,
                    $0.identifierPatternNode != nil,
                    $0.identifierTypeNode != nil
                else { return false }
                return true
            }
        guard let initializer = InitializerDeclSyntax.buildFromVariables(initializeVariables) else { return nil }
        let newMembers = MemberBlockItemListSyntax(members + [MemberBlockItemSyntax(decl: initializer)])
        let newMemberBlock = memberBlock.with(\.members, newMembers)
        return with(\.memberBlock, newMemberBlock)
    }
}

private extension VariableDeclSyntax {
    var isOptionalDecl: Bool? {
        bindings.first?.typeAnnotation?.type.is(OptionalTypeSyntax.self)
    }
    
    var hasInitializerDecl: Bool? {
        bindings.first?.initializer != nil
    }
    
    var identifierPatternNode: IdentifierPatternSyntax? {
        guard let binding = bindings.first else { return nil }
        return binding.pattern.as(IdentifierPatternSyntax.self)
    }
    
    var identifierTypeNode: IdentifierTypeSyntax? {
        guard 
            let binding = bindings.first,
            let typeAnnotation = binding.typeAnnotation
        else { return nil }
        return typeAnnotation.type.as(IdentifierTypeSyntax.self)
    }
}

private extension InitializerDeclSyntax {
    static func buildFromVariables(_ nodes: [VariableDeclSyntax]) -> Self? {
        guard
            let signature = buildFunctionSignature(from: nodes),
            let codeBlock = buildCodeBlock(from: nodes)
        else { return nil }
        let leading = nodes[0].bindingSpecifier.leadingTrivia
        return .init(
            initKeyword: .keyword(.`init`, leadingTrivia: leading.appending(TriviaPiece.newlines(2))),
            signature: signature,
            body: codeBlock
        )
    }
    
    static func buildFunctionSignature(from variables: [VariableDeclSyntax]) -> FunctionSignatureSyntax? {
        let parameters: [FunctionParameterSyntax] = variables.enumerated().compactMap { index, vnode -> FunctionParameterSyntax? in
            guard
                let identifierPattern = vnode.identifierPatternNode,
                let identifierType = vnode.identifierTypeNode,
                let type = TypeSyntax(identifierType.name)
            else { return nil }
            var node: FunctionParameterSyntax = .init(
                firstName: identifierPattern.identifier,
                type: type
            )
            if index != variables.endIndex - 1 {
                node = node.with(\.trailingComma, .commaToken())
            }
            return node
        }
        guard parameters.isEmpty == false else { return nil }
        return .init(parameterClause: .init(
            leftParen: .leftParenToken(),
            parameters: FunctionParameterListSyntax(parameters),
            rightParen: .rightParenToken()
        ))
    }

    static func buildCodeBlock(from variables: [VariableDeclSyntax]) -> CodeBlockSyntax? {
        let codeBlockItems: [CodeBlockItemSyntax] = variables.compactMap { vnode -> CodeBlockItemSyntax? in
            guard let identifierPattern = vnode.identifierPatternNode else { return nil }
            let expr = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .keyword(.`self`)),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: identifierPattern.identifier)
                ),
                operator: AssignmentExprSyntax(),
                rightOperand: DeclReferenceExprSyntax(baseName: identifierPattern.identifier)
            )
            let node: CodeBlockItemSyntax = .init(item: .expr(ExprSyntax(expr)))
            return node
        }
        guard codeBlockItems.isEmpty == false else { return nil }
        return .init(statements: CodeBlockItemListSyntax(codeBlockItems))
    }
}


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
    let y: Int
    var foo: Int?
    let bar = ""
    var baz: Int = 0

    struct Inner {
        let p: Int
        let q: Int
    }
}
"""
        
        let expected = """
struct Test {
    let x: Int
    let y: Int
    var foo: Int?
    let bar = ""
    var baz: Int = 0

    struct Inner {
        let p: Int
        let q: Int

        public init(p: Int, q: Int) {
            self.p = p
            self.q = q
        }
    }

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
"""
        let sourceFile = Parser.parse(source: source)
        let rewriter = _ModifierRewriter()
        let modifiedSource = rewriter.visit(sourceFile)
        XCTAssertEqual(modifiedSource.description, expected)
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
                    $0.isOptionalDecl != true,
                    $0.hasInitializerDecl != true,
                    $0.identifierPatternNode != nil,
                    $0.identifierTypeNode != nil
                else { return false }
                return true
            }
        guard initializeVariables.isEmpty == false else { return nil }
        guard let initializer = InitializerDeclSyntax.buildFromVariables(initializeVariables) else { return nil }
        let newMembers = MemberBlockItemListSyntax(members + [MemberBlockItemSyntax(decl: initializer)])
        let newMemberBlock = memberBlock.with(\.members, newMembers)
        let ret = with(\.memberBlock, newMemberBlock)
        return ret
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
        guard let binding = bindings.first else {
            return nil
        }
        return binding.pattern.as(IdentifierPatternSyntax.self)
    }
    
    var identifierTypeNode: IdentifierTypeSyntax? {
        guard 
            let binding = bindings.first,
            let typeAnnotation = binding.typeAnnotation
        else {
            return nil
        }
        return typeAnnotation.type.as(IdentifierTypeSyntax.self)
    }
}

private extension InitializerDeclSyntax {
    static func buildFromVariables(_ nodes: [VariableDeclSyntax]) -> Self? {
        precondition(nodes.isEmpty == false)
        let currentLeading = nodes[0].bindingSpecifier.leadingTrivia
        guard
            let signature = buildFunctionSignature(from: nodes),
            let codeBlock = buildCodeBlock(from: nodes, leading: currentLeading)
        else { return nil }
        
        let leadingPieces: [TriviaPiece] = currentLeading.pieces.reduce(into: []) { curr, piece in
            switch piece {
            case .newlines:
                // Ensure 1 blank line before line of `init`
                curr.append(.newlines(2))
            case let .spaces(val):
                // Keep indent
                curr.append(.spaces(val))
            default:
                break
            }
        }
        let publicModifier = DeclModifierSyntax(
            leadingTrivia: .init(pieces: leadingPieces),
            name: .keyword(.public),
            trailingTrivia: .space
        )
        
        return .init(
            initKeyword: .keyword(
                .`init`
            ),
            signature: signature,
            body: codeBlock
        )
        .with(\.modifiers, DeclModifierListSyntax([publicModifier]))
    }
    
    static func buildFunctionSignature(from variables: [VariableDeclSyntax]) -> FunctionSignatureSyntax? {
        let parameters: [FunctionParameterSyntax] = variables.enumerated().compactMap { index, vnode -> FunctionParameterSyntax? in
            guard
                let identifierPattern = vnode.identifierPatternNode,
                let identifierType = vnode.identifierTypeNode,
                let type = TypeSyntax(identifierType)
            else {
                return nil
            }
            var node: FunctionParameterSyntax = .init(
                firstName: identifierPattern.identifier,
                colon: .colonToken(trailingTrivia: .space),
                type: type
            )
            if index != variables.endIndex - 1 {
                node = node.with(\.trailingComma, .commaToken(trailingTrivia: .space))
            }
            return node
        }
        guard parameters.isEmpty == false else { return nil }
        return .init(parameterClause: .init(
            leftParen: .leftParenToken(),
            parameters: FunctionParameterListSyntax(parameters),
            rightParen: .rightParenToken(trailingTrivia: .space)
        ))
    }

    static func buildCodeBlock(from variables: [VariableDeclSyntax], leading: Trivia) -> CodeBlockSyntax? {
        let codeBlockItems: [CodeBlockItemSyntax] = variables.compactMap { vnode -> CodeBlockItemSyntax? in
            guard let identifierPattern = vnode.identifierPatternNode else { return nil }
            let expr = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .keyword(
                            .`self`,
                            leadingTrivia: leading
                                .appending(TriviaPiece.spaces(4))
                        )
                    ),
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(
                        baseName: identifierPattern.identifier
                            .with(\.trailingTrivia, .space)
                    )
                ),
                operator: AssignmentExprSyntax(trailingTrivia: .space),
                rightOperand: DeclReferenceExprSyntax(baseName: identifierPattern.identifier)
            )
            let node: CodeBlockItemSyntax = .init(item: .expr(ExprSyntax(expr)))
            return node
        }
        guard codeBlockItems.isEmpty == false else { return nil }
        return .init(
            statements: CodeBlockItemListSyntax(codeBlockItems),
            rightBrace: .rightBraceToken(leadingTrivia: leading)
        )
    }
}

import SwiftSyntax

extension StructDeclSyntax {
    func makePublicInitializerMemberBlock() -> InitializerDeclSyntax? {
        let members = Array(memberBlock.members)
        guard members.isEmpty == false else { return nil }
        let initializerDecls = members
            .compactMap { $0.decl.as(InitializerDeclSyntax.self) }
        guard initializerDecls.isEmpty == true else { return nil }
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
        return initializer
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

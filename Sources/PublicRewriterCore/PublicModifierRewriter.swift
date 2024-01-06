import SwiftSyntax

public class PublicModifierRewriter: SyntaxRewriter {
    override public func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard 
            let parent = node.parent,
            parent.is(MemberBlockItemSyntax.self)
        else { return super.visit(node) }
        
        guard
            let newModifiers = VariableDeclSyntax.makeNewPublicModifiers(from: node),
            case let .keyword(keyword) = node.bindingSpecifier.tokenKind
        else { return super.visit(node) }
        
        let newNode = node
            .with(\.bindingSpecifier, .keyword(keyword, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
        return super.visit(newNode)
    }

    override public func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard node.shouldMakePublicInExtension else { return super.visit(node) }
        
        guard node.modifiers.isEmpty else { return super.visit(node) }
        var newNode = node
            .with(\.structKeyword, .keyword(.struct, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.structKeyword.leadingTrivia))

        if let initializerDecl = node.makePublicInitializerMemberBlock() {
            let newMembers = MemberBlockItemListSyntax(
                Array(node.memberBlock.members) +
                [MemberBlockItemSyntax(decl: initializerDecl)]
            )
            newNode = newNode
                .with(\.memberBlock, node.memberBlock.with(\.members, newMembers))
        }
        return super.visit(DeclSyntax(newNode))
    }

    override public func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard node.shouldMakePublicInExtension else { return super.visit(node) }

        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.enumKeyword, .keyword(.enum, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.enumKeyword.leadingTrivia))
        return super.visit(DeclSyntax(newNode))
    }
    
    override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard node.shouldMakePublicInExtension else { return super.visit(node) }

        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.classKeyword, .keyword(.class, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.classKeyword.leadingTrivia))
        return super.visit(DeclSyntax(newNode))
    }
    
    override public func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard let newModifiers = InitializerDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node)}

        let newNode = node
            .with(\.initKeyword, .keyword(.`init`))
            .with(\.modifiers, newModifiers)
            .cast(InitializerDeclSyntax.self)

        return super.visit(newNode)
    }

    override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard let newModifiers = FunctionDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node) }

        let newNode = node
            .with(\.funcKeyword, .keyword(.func, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
            .cast(FunctionDeclSyntax.self)

        return super.visit(newNode)
    }
    
    override public func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard let newModifiers = ExtensionDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node) }

        let newNode = node
            .with(\.extensionKeyword, .keyword(.extension, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
            .cast(ExtensionDeclSyntax.self)

        return super.visit(newNode)
    }
    
    override public func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.isPublic }) {
            return super.visit(node)
        }
        guard node.modifiers.isEmpty else { return super.visit(node) }

        let newNode = node
            .with(\.protocolKeyword, .keyword(.protocol, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.protocolKeyword.leadingTrivia))
            .cast(ProtocolDeclSyntax.self)

        return super.visit(newNode)
    }
}

private extension PublicModifierRewriter {
    func makePublicDeclModifier(leadingTrivia: Trivia) -> DeclModifierListSyntax {
        DeclModifierListSyntax([
            DeclModifierSyntax(
                leadingTrivia: leadingTrivia,
                name: .keyword(.public),
                trailingTrivia: .spaces(1)
            )
        ])
    }
}

private extension DeclModifierSyntax {
    var isPublic: Bool {
        name.text == "public"
    }
}

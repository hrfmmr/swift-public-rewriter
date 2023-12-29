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
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        guard node.shouldMakePublicInExtension else { return super.visit(node) }
        
        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.structKeyword, .keyword(.struct, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.structKeyword.leadingTrivia))
        return super.visit(DeclSyntax(newNode))
    }

    override public func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
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
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
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
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
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
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        guard let newModifiers = FunctionDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node)}

        let newNode = node
            .with(\.funcKeyword, .keyword(.func, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
            .cast(FunctionDeclSyntax.self)

        return super.visit(newNode)
    }
    
    override public func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        guard node.modifiers.isEmpty else { return super.visit(node) }

        let newNode = node
            .with(\.extensionKeyword, .keyword(.extension, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier(leadingTrivia: node.extensionKeyword.leadingTrivia))
            .cast(ExtensionDeclSyntax.self)

        return super.visit(newNode)
    }
    
    override public func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
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

private extension SyntaxProtocol {
    /// for `struct`, `enum`, `class`, etc..
    var shouldMakePublicInExtension: Bool {
        guard
            isDefinedInExtension(ofDeclModifierString: "private") == false,
            isDefinedInExtension(ofDeclModifierString: "public") == false
        else { return false }
        return true
    }

    /// for `struct`, `enum`, `class`, etc..
    func isDefinedInExtension(ofDeclModifierString declModifierString: String) -> Bool {
        precondition(["private", "public"].contains(declModifierString))
        
        var ancestor = parent
        while let this = ancestor, this.is(CodeBlockItemSyntax.self) == false {
            ancestor = ancestor?.parent
            guard ancestor != nil else {
                assertionFailure("❗️Unexpected AST tree. `CodeBlockItemSyntax` must exist on ancestors.")
                return false
            }
            
            if let extNode = ancestor!.as(ExtensionDeclSyntax.self) {
                let modifiers = Array(extNode.modifiers)
                if modifiers.count == 1, modifiers[0].name.text == declModifierString {
                    return true
                }
            }
        }
        return false
    }
}


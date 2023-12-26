import SwiftSyntax

class PublicModifierRewriter: SyntaxRewriter {
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        guard 
            let parent = node.parent,
            parent.is(MemberBlockItemSyntax.self)
        else { return super.visit(node) }
        
        guard
            let newModifiers = VariableDeclSyntax.makeNewPublicModifiers(from: node),
            case let .keyword(keyword) = node.bindingSpecifier.tokenKind
        else { return super.visit(node) }

        print("🟠node(VariableDeclSyntax):\(node.description)")
        
        let newNode = node
            .with(\.bindingSpecifier, .keyword(keyword, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
        return super.visit(newNode)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🟣node(StructDeclSyntax):\(node.name)")
        guard node.shouldMakePublicInExtension else { return super.visit(node) }
        
        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.structKeyword, .keyword(.struct, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier())
        return super.visit(DeclSyntax(newNode))
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🟣node(EnumDeclSyntax):\(node.name)")
        guard node.shouldMakePublicInExtension else { return super.visit(node) }

        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.enumKeyword, .keyword(.enum, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier())
        return super.visit(DeclSyntax(newNode))
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🟣node(ClassDeclSyntax):\(node.name)")
        guard node.shouldMakePublicInExtension else { return super.visit(node) }

        guard node.modifiers.isEmpty else { return super.visit(node) }
        let newNode = node
            .with(\.classKeyword, .keyword(.class, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier())
        return super.visit(DeclSyntax(newNode))
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        guard let newModifiers = InitializerDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node)}

        print("🔵node(InitializerDeclSyntax):\(node.description)")

        let newNode = node
            .with(\.initKeyword, .keyword(.`init`))
            .with(\.modifiers, newModifiers)
            .cast(InitializerDeclSyntax.self)

        return super.visit(newNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        guard let newModifiers = FunctionDeclSyntax.makeNewPublicModifiers(from: node) else { return super.visit(node)}

        print("🔵node(FunctionDeclSyntax):\(node.description)")

        let newNode = node
            .with(\.funcKeyword, .keyword(.func, trailingTrivia: .spaces(1)))
            .with(\.modifiers, newModifiers)
            .cast(FunctionDeclSyntax.self)

        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🟤node(ExtensionDeclSyntax):\(node.description)")
        guard node.modifiers.isEmpty else { return super.visit(node) }

        let newNode = node
            .with(\.extensionKeyword, .keyword(.extension, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier())
            .cast(ExtensionDeclSyntax.self)

        return super.visit(newNode)
    }
}

private extension PublicModifierRewriter {
    func makePublicDeclModifier() -> DeclModifierListSyntax {
        DeclModifierListSyntax([
            DeclModifierSyntax(
                leadingTrivia: .newlines(2),
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


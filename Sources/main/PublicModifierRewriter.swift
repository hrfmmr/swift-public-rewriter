import SwiftSyntax

private extension VariableDeclSyntax {
    /// Whether `private(set) var ...`
    var hasPrivateSetVar: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "private", let detail = modifier.detail, detail.detail.text == "set"
        else { return false }
        return true
    }
    
    /// Whether `lazy var ...`
    var hasLazyVar: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "lazy" else { return false }
        return true
    }
    
    static func makeNewPublicModifiers(from node: VariableDeclSyntax) -> DeclModifierListSyntax? {
        guard let pattern = MakePublicDeclPattern.from(node) else { return nil }
        let publicModifier = DeclModifierSyntax(
            leadingTrivia: .newlines(1),
            name: .keyword(.public),
            trailingTrivia: .spaces(1)
        )
        var modifiers = DeclModifierListSyntax([
            publicModifier,
        ])
        
        switch pattern {
        case .defaultInternal:
            break
        case .internalPrivateSetVar:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.private),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier.with(\.detail, Array(node.modifiers)[0].detail))
        case .internalLazyVar:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.lazy),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier)
        }
        return modifiers
    }
    
    
    enum MakePublicDeclPattern {
        /// No access scope defined(internal)
        /// `let ...`
        /// `var ...`
        case defaultInternal
        
        /// internal scope of `private(set) var ...`
        case internalPrivateSetVar
        
        /// internal scope of `lazy var ...`
        case internalLazyVar
        
        static func from(_ node: VariableDeclSyntax) -> Self? {
            if node.hasPrivateSetVar {
                .internalPrivateSetVar
            } else if node.hasLazyVar {
                .internalLazyVar
            } else if node.modifiers.isEmpty {
                .defaultInternal
            } else {
                nil
            }
        }
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
        print("🔵node(InitializerDeclSyntax):\(node.description)")
        guard node.modifiers.isEmpty else { return super.visit(node) }

        let newNode = node
            .with(\.initKeyword, .keyword(.`init`))
            .with(\.modifiers, makePublicDeclModifier())
            .cast(InitializerDeclSyntax.self)

        return super.visit(newNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if node.modifiers.contains(where: { $0.name.text == "public" }) {
            return super.visit(node)
        }
        print("🔵node(FunctionDeclSyntax):\(node.description)")
        guard node.modifiers.isEmpty else { return super.visit(node) }

        let newNode = node
            .with(\.funcKeyword, .keyword(.func, trailingTrivia: .spaces(1)))
            .with(\.modifiers, makePublicDeclModifier())
            .cast(FunctionDeclSyntax.self)

        return super.visit(newNode)
    }
}

private func makePublicDeclModifier() -> DeclModifierListSyntax {
    DeclModifierListSyntax([
        DeclModifierSyntax(
            leadingTrivia: .newlines(2),
            name: .keyword(.public),
            trailingTrivia: .spaces(1)
        )
    ])
}

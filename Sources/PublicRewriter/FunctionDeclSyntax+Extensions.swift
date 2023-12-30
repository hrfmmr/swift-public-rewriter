import SwiftSyntax

extension FunctionDeclSyntax {
    private enum MakePublicDeclPattern {
        /// No modifiers
        case normalFunc
        
        /// `static func`
        case staticFunc
        
        /// `override func`
        case overrideFunc
        
        /// `mutating func`
        case mutatingFunc
        
        static func from(_ node: FunctionDeclSyntax) -> Self? {
            if node.hasStaticModifier {
                .staticFunc
            } else if node.hasOverrideModifier {
                .overrideFunc
            } else if node.hasMutatingModifier {
                .mutatingFunc
            } else if node.modifiers.isEmpty {
                .normalFunc
            } else {
                nil
            }
        }
    }

    private var hasStaticModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "static" else { return false }
        return true
    }
    
    private var hasOverrideModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "override" else { return false }
        return true
    }
    
    private var hasMutatingModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "mutating" else { return false }
        var ancestor = parent
        while let this = ancestor, this.is(CodeBlockItemSyntax.self) == false {
            ancestor = ancestor?.parent
            guard ancestor != nil else {
                assertionFailure("❗️Unexpected AST tree. `CodeBlockItemSyntax` must exist on ancestors.")
                return false
            }
            
            if let structNode = ancestor!.as(StructDeclSyntax.self) {
                return true
            }
        }
        return false
    }
    
    static func makeNewPublicModifiers(from node: FunctionDeclSyntax) -> DeclModifierListSyntax? {
        guard let pattern = MakePublicDeclPattern.from(node) else { return nil }
        let publicModifier = DeclModifierSyntax(
            leadingTrivia: node.leadingTrivia,
            name: .keyword(.public),
            trailingTrivia: .spaces(1)
        )
        var modifiers = DeclModifierListSyntax([
            publicModifier,
        ])
        
        switch pattern {
        case .normalFunc:
            break
        case .staticFunc:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.static),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier)
        case .overrideFunc:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.override),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier)
        case .mutatingFunc:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.mutating),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier)
        }
        return modifiers
    }    
}


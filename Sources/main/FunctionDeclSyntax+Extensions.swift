import SwiftSyntax

extension FunctionDeclSyntax {
    var hasStaticModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "static" else { return false }
        return true
    }
    
    var hasOverrideModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "override" else { return false }
        return true
    }
    
    static func makeNewPublicModifiers(from node: FunctionDeclSyntax) -> DeclModifierListSyntax? {
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
        }
        return modifiers
    }
    
    enum MakePublicDeclPattern {
        /// No modifiers
        case normalFunc
        
        /// `static func`
        case staticFunc
        
        /// `override func`
        case overrideFunc
        
        static func from(_ node: FunctionDeclSyntax) -> Self? {
            if node.hasStaticModifier {
                .staticFunc
            } else if node.hasOverrideModifier {
                .overrideFunc
            } else if node.modifiers.isEmpty {
                .normalFunc
            } else {
                nil
            }
        }
    }
}


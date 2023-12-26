import SwiftSyntax

extension InitializerDeclSyntax {
    private enum MakePublicDeclPattern {
        /// No modifiers
        case normalInit
        
        /// `override init`
        case overrideInit
        
        static func from(_ node: InitializerDeclSyntax) -> Self? {
            if node.hasOverrideModifier {
                .overrideInit
            } else if node.modifiers.isEmpty {
                .normalInit
            } else {
                nil
            }
        }
    }

    private var hasOverrideModifier: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "override" else { return false }
        return true
    }

    static func makeNewPublicModifiers(from node: InitializerDeclSyntax) -> DeclModifierListSyntax? {
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
        case .normalInit:
            break
        case .overrideInit:
            let existingModifier = DeclModifierSyntax(
                name: .keyword(.override),
                trailingTrivia: .spaces(1)
            )
            modifiers.append(existingModifier)
        }
        return modifiers
    }
}

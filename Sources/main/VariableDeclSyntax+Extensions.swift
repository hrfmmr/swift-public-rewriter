import SwiftSyntax

extension VariableDeclSyntax {
    private enum MakePublicDeclPattern {
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

    /// Whether `private(set) var ...`
    private var hasPrivateSetVar: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard
            modifier.name.text == "private",
            let detail = modifier.detail, detail.detail.text == "set"
        else { return false }
        return true
    }
    
    /// Whether `lazy var ...`
    private var hasLazyVar: Bool {
        let modifiers = Array(modifiers)
        guard modifiers.count == 1 else { return false }
        let modifier = modifiers[0]
        guard modifier.name.text == "lazy" else { return false }
        return true
    }
    
    static func makeNewPublicModifiers(from node: VariableDeclSyntax) -> DeclModifierListSyntax? {
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
}

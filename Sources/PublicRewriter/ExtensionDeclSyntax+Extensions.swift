import SwiftSyntax

extension ExtensionDeclSyntax {
    private enum MakePublicDeclPattern {
        case withoutInheritance(hasModifiers: Bool)
        
        static func from(_ node: ExtensionDeclSyntax) -> Self? {
            if node.hasInheritanceClause {
                nil
            } else {
                .withoutInheritance(hasModifiers: node.hasModifiers)
            }
        }
    }
    
    private var hasModifiers: Bool {
        Array(modifiers).isEmpty == false
    }
    
    private var hasInheritanceClause: Bool {
        inheritanceClause != nil
    }
    
    static func makeNewPublicModifiers(from node: Self) -> DeclModifierListSyntax? {
        guard let pattern = MakePublicDeclPattern.from(node) else { return nil }
        let publicModifier = DeclModifierSyntax(
            leadingTrivia: node.leadingTrivia,
            name: .keyword(.public),
            trailingTrivia: .spaces(1)
        )
        let modifiers = DeclModifierListSyntax([
            publicModifier,
        ])
        
        switch pattern {
        case let .withoutInheritance(hasModifiers):
            switch hasModifiers {
            case true:
                return nil
            case false:
                break
            }
        }
        return modifiers
    }
}

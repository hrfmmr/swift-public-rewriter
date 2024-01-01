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

        /// defined as a protocol conformance
        case protocolConformance
        
        static func from(_ node: FunctionDeclSyntax) -> Self? {
            if node.isDefinedInProtocol {
                nil
            } else if node.hasStaticModifier {
                .staticFunc
            } else if node.hasOverrideModifier {
                .overrideFunc
            } else if node.hasMutatingModifier {
                .mutatingFunc
            } else if node.isDefinedAsProtocolConformance {
                .protocolConformance
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

        guard let _ = findAncestorNode(of: StructDeclSyntax.self, baseNodeType: CodeBlockItemSyntax.self)
        else { return false }
        return true
    }
    
    private var isDefinedInProtocol: Bool {
        guard let _ = findAncestorNode(of: ProtocolDeclSyntax.self, baseNodeType: CodeBlockItemSyntax.self)
        else { return false }
        return true
    }

    private var isDefinedAsProtocolConformance: Bool {
        guard let extNode = findAncestorNode(of: ExtensionDeclSyntax.self, baseNodeType: CodeBlockItemSyntax.self)
        else { return false }
        return extNode.inheritanceClause != nil
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
        case .normalFunc, .protocolConformance:
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


import SwiftSyntax

extension SyntaxProtocol {
    /// for `struct`, `enum`, `class`, etc..
    var shouldMakePublicInExtension: Bool {
        guard
            isDefinedInExtension(ofDeclModifierString: "private") == false,
            isDefinedInExtension(ofDeclModifierString: "public") == false
        else { return false }
        return true
    }
    
    func findAncestorNode<T: SyntaxProtocol>(of targetNodeType: T.Type, baseNodeType: SyntaxProtocol.Type) -> T? {
        var ancestor = parent
        while let this = ancestor, this.is(baseNodeType.self) == false {
            ancestor = ancestor?.parent
            guard ancestor != nil else {
                assertionFailure("❗️Unexpected AST tree. `\(type(of: baseNodeType))` must exist on ancestors.")
                return nil
            }
            
            if let node = ancestor!.as(targetNodeType) {
                return node
            }
        }
        return nil
    }

    /// for `struct`, `enum`, `class`, etc..
    private func isDefinedInExtension(ofDeclModifierString declModifierString: String) -> Bool {
        precondition(["private", "public"].contains(declModifierString))
        
        guard let extNode = findAncestorNode(of: ExtensionDeclSyntax.self, baseNodeType: CodeBlockItemSyntax.self) else { return false }
        let modifiers = Array(extNode.modifiers)
        if modifiers.count == 1, modifiers[0].name.text == declModifierString {
            return true
        }
        return false
    }
}

import Foundation
import SwiftUI

class Baz {
    let x: String
    
    init(x: String) {
        self.x = x
    }
    
    func doSomething() {}
    
    class InnerBaz {
        var xx: Int = 0
    }
}

import Foundation
import SwiftUI

class Baz {
    let bazX: Int
    var bazY: Int?
    private (set) var hoge: String?
    lazy var lz: String = {
        "lazy"
    }()
    
    init(x: Int) {
        self.bazX = x
    }
    
    func doSomething() {
        let s = ""
        var i = 0
    }
    
    class InnerBaz {
        let xx: Int = 0
    }
}

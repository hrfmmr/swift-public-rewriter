import Foundation

open class OpenClass {
    open func doSomething() {}
}

class ExampleClass: OpenClass {
    let x: Int = 0
    var y: Int?
    private (set) var z: String?
    lazy var lz: String = {
        "lazy"
    }()
    override init() {
        super.init()
    }
    override func doSomething() {
        let _ = ""
        var _ = 0
    }
    
    class InnerBaz {
        let x: Int = 0
    }
}

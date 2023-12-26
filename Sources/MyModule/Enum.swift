import Foundation

enum ExampleEnum {
    case a, b, c
    var string: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        }
    }
    
    func makeString() -> String {
        string
    }
}

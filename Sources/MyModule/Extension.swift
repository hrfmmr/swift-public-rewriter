import Foundation

private extension ExampleStruct {
    struct InnerPrivateExampleStruct {}
    enum InnerPrivateExampleEnum {}
    class InnerPrivateExampleClass {}
}

extension ExampleStruct {
    struct InnerExampleStruct {}
    enum InnerExampleEnum {}
    class InnerExampleClass {}
}

public struct ExamplePublicStruct {}

public extension ExamplePublicStruct {
    struct InnerPublicExampleStrut {}
    enum InnerPublicExampleEnum {}
    class InnerPublicExampleClass {}
}

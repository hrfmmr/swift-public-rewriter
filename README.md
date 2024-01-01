## swift-public-rewriter
[![Continuous Integration Status](https://github.com/hrfmmr/swift-public-rewriter/workflows/CI/badge.svg)](https://github.com/hrfmmr/swift-public-rewriter/workflows/CI/badge.svg)

## Overview
swift-public-rewriter is a tool designed to perform semantic code conversions by using [SwiftSyntax](https://swiftpackageindex.com/apple/swift-syntax), automatically changing internal scope definitions in Swift source files to `public` scope.
This is particularly useful in the context of modularization, where exposing internal components is necessary for compiling.

## Example

Before

```swift
import Foundation

open class OpenClass {
    open func doSomething() {}
}

class InheritedClass: OpenClass {
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
    
    class Inner {
        let x: Int = 0
    }
}

struct ExampleStruct {
    let x: Int
    var y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    func doSomething() {
        let _ = ""
        var _ = 0
    }

    mutating func updateY(_ y: Int) {
        self.y = y
    }

    static func from(x: Int) -> Self {
        .init(x: x, y: 0)
    }
}

protocol TestProtocol {
    var x: Int { get }
    func test()
}

struct Foo {}

extension Foo: TestProtocol {
    var x: Int { 0 }
    func test() {}
}
```

After

```swift
import Foundation

open class OpenClass {
    open func doSomething() {}
}

public class InheritedClass: OpenClass {
    public let x: Int = 0
    public var y: Int?
    public private (set) var z: String?
    public lazy var lz: String = {
        "lazy"
    }()
    public override init() {
        super.init()
    }
    public override func doSomething() {
        let _ = ""
        var _ = 0
    }
    
    public class Inner {
        public let x: Int = 0
    }
}

public struct ExampleStruct {
    public let x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func doSomething() {
        let _ = ""
        var _ = 0
    }

    public mutating func updateY(_ y: Int) {
        self.y = y
    }

    public static func from(x: Int) -> Self {
        .init(x: x, y: 0)
    }
}

public protocol TestProtocol {
    var x: Int { get }
    func test()
}

public struct Foo {}

extension Foo: TestProtocol {
    public var x: Int { 0 }
    public func test() {}
}
```

## Usage

Execute the following command from the command line:

```bash
swift run swift-public-rewriter <path-to-file-or-directory>
```

## Installation

```bash
make

# Add `.build/release/swift-public-rewriter` executable to your PATH
export PATH=/path/to/swift-public-rewriter:$PATH
```

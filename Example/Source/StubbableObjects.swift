//
//  Stub.swift
//  SpryExample
//
//  Created by Brian Radebaugh on 7/16/17.
//  Copyright © 2017 Brian Radebaugh. All rights reserved.
//

import Foundation

/**
 Object return by `stub()` call. Used to specify arguments and return values when stubbing.
 */

public class Stub: CustomStringConvertible {
    enum StubType {
        case andReturn(Any?)
        case andDo(([Any?]) -> Any?)
    }

    private var stubType: StubType?

    internal let functionName: String
    internal private(set) var arguments: [SpryEquatable] = []

    internal init(functionName: String) {
        self.functionName = functionName
    }

    // MARK: - Public Functions

    /// A beautified description. Used for debugging purposes.
    public var description: String {
        let argumentsDescription = arguments.map{"<\($0)>"}.joined(separator: ", ")
        let returnDescription = isNil(stubType) ? "nil" : "\(stubType!)"
        return "Stub(function: <\(functionName)>, args: <\(argumentsDescription)>, returnValue: <\(returnDescription)>)"
    }

    /**
     Used to specify arguments when stubbing.

     - Note: If no arguments are specified then any arguments may be passed in and the stubbed value will still be returned.

     ## Example ##
     ```swift
     service.stub("functionSignature").with("expected argument")
     ```

     - Parameter arguments: The specified arguments needed for the stub to succeed. See `Argument` for ways other ways of constraining expected arguments besides Equatable.

     - Returns: A stub object used to add additional `with()` or to add `andReturn()` or `andDo()`.
     */
    public func with(_ arguments: SpryEquatable...) -> Stub {
        self.arguments += arguments
        return self
    }

    /**
     Used to specify the return value for the stubbed function.

     - Important: This allows `Any` object to be passed in but the stub will ONLY work if the correct type is passed in.

     - Note: ONLY the last `andReturn()` or `andDo()` will be used. If multiple stubs are required (for instance with different argument specifiers) then a different stub object is required (i.e. call the `stub()` function again).

     ## Example ##
     ```swift
     // arguments do NOT matter
     service.stub("functionSignature()").andReturn("stubbed value")

     // arguments matter
     service.stub("functionSignature()").with("expected argument").andReturn("stubbed value")
     ```

     - Parameter value: The value to be returned by the stubbed function.
     */
    public func andReturn(_ value: Any?) {
        stubType = .andReturn(value)
    }

    /**
     Used to specify a closure to be executed in place of the stubbed function.

     - Note: ONLY the last `andReturn()` or `andDo()` will be used. If multiple stubs are required (for instance with different argument specifiers) then a different stub object is required (i.e. call the `stub()` function again).

     ## Example ##
     ```swift
     // arguments do NOT matter (closure will be called if `functionSignature()` is called)
     service.stub("functionSignature()").andDo { arguments in
         // do test specific things (like call a completion block)
         return "stubbed value"
     }

     // arguments matter (closure will NOT be called unless the arguments match what is passed in the `with()` function)
     service.stub("functionSignature()").with("expected argument").andDo { arguments in
         // do test specific things (like call a completion block)
         return "stubbed value"
     }
     ```

     - Parameter closure: The closure to be executed. The array of parameters that will be passed in correspond to the parameters being passed into the stubbed function. The return value must match the stubbed function's return type and will be the return value of the stubbed function.
     */
    public func andDo(_ closure: @escaping ([Any?]) -> Any?) {
        stubType = .andDo(closure)
    }

    // MARK: - Internal Functions

    internal func returnValue(for args: [Any?]) -> Any? {
        guard let stubType = stubType else {
            fatalError("Must add `andReturn` or `andDo` to properly stub an object")
        }

        switch stubType {
        case .andReturn(let value):
            return value
        case .andDo(let closure):
            return closure(args)
        }
    }
}

/**
 This exists because an array is needed as a class. Instances of this type are put into an NSMapTable.
 */
internal class StubArray {
    var stubs: [Stub] = []
}

/**
 Used to determine if a fallback was given in the event of that no stub is found.
 */
internal enum Fallback<T> {
    case noFallback
    case fallback(T)
}
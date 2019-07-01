import AST
import Token

extension Environment {
    static let builtins = Environment(
        map: [
            "len": Builtin { arguments in
                guard let argument = arguments.first, arguments.count == 1 else {
                    return Error.invalidNumberOfArguments(functionName: "len", expected: 1, got: arguments.count)
                }

                switch argument {
                case let string as StringValue:
                    return Integer(value: Int64(string.value.count))

                case let array as ArrayValue:
                    return Integer(value: Int64(array.elements.count))

                default:
                    return Error.invalidArgument(type: type(of: argument), functionName: "len")
                }
            },
            "first": Builtin { arguments in
                guard let argument = arguments.first, arguments.count == 1 else {
                    return Error.invalidNumberOfArguments(functionName: "first", expected: 1, got: arguments.count)
                }

                guard let array = argument as? ArrayValue else {
                    return Error.invalidArgument(type: type(of: argument), functionName: "first")
                }

                return array.elements.first ?? Null()
            },
            "last": Builtin { arguments in
                guard let argument = arguments.first, arguments.count == 1 else {
                    return Error.invalidNumberOfArguments(functionName: "last", expected: 1, got: arguments.count)
                }

                guard let array = argument as? ArrayValue else {
                    return Error.invalidArgument(type: type(of: argument), functionName: "last")
                }

                return array.elements.last ?? Null()
            },
            "rest": Builtin { arguments in
                guard let argument = arguments.first, arguments.count == 1 else {
                    return Error.invalidNumberOfArguments(functionName: "rest", expected: 1, got: arguments.count)
                }

                guard let array = argument as? ArrayValue else {
                    return Error.invalidArgument(type: type(of: argument), functionName: "rest")
                }

                let rest = Array(array.elements.dropFirst())
                return ArrayValue(elements: rest)
            },
            "push": Builtin { arguments in
                guard arguments.count == 2 else {
                    return Error.invalidNumberOfArguments(functionName: "push", expected: 2, got: arguments.count)
                }

                guard let array = arguments[0] as? ArrayValue else {
                    return Error.invalidArgument(type: type(of: arguments[0]), functionName: "push")
                }

                var newElements = array.elements
                newElements.append(arguments[1])
                return ArrayValue(elements: newElements)
            },
            "puts": Builtin { arguments in
                for argument in arguments {
                    print(argument.description)
                }

                return Null()
            },
        ]
    )
}

import AST

public protocol Value: CustomStringConvertible {}

extension Value {
    var type: Value.Type {
        return Swift.type(of: self)
    }

    var isError: Bool {
        return self is Error
    }
}

public struct Integer: Value, Hashable {
    public var value: Int64

    public var description: String {
        return value.description
    }

    public init(value: Int64) {
        self.value = value
    }
}

public struct StringValue: Value, Hashable {
    public var value: String

    public var description: String {
        return value.description
    }

    public init(value: String) {
        self.value = value
    }
}

public struct Boolean: Value, Hashable {
    public var value: Bool

    public var description: String {
        return value.description
    }

    public init(value: Bool) {
        self.value = value
    }
}

public struct Null: Value {
    public var description: String {
        return "null"
    }

    public init() {}
}

public struct ReturnValue: Value {
    public var value: Value

    public var description: String {
        return value.description
    }

    public init(value: Value) {
        self.value = value
    }
}

public struct Function: Value {
    public var expression: FunctionExpression
    public var environment: Environment

    public var description: String {
        return expression.description
    }

    public init(expression: FunctionExpression, environment: Environment) {
        self.expression = expression
        self.environment = environment
    }
}

public struct Builtin: Value {
    public var function: ([Value]) -> Value

    public var description: String {
        return "Builtin function"
    }
}

public struct ArrayValue: Value {
    public var elements: [Value]

    public var description: String {
        let elements = self.elements.lazy
            .map { $0.description }
            .joined(separator: ", ")
        return "[\(elements)]"
    }
}

public struct Hash: Value {
    public var pairs: [AnyHashable: Value]

    public var description: String {
        let pairs = self.pairs.lazy
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
        return "{\(pairs)}"
    }
}

public enum Error: Value {
    case unknownInfixOperator(left: Value.Type, operator: String, right: Value.Type)
    case unknownPrefixOperator(operator: String, right: Value.Type)
    case undefinedIdentifier(name: String)
    case callNonFunctionValue(type: Value.Type)
    case invalidArgument(type: Value.Type, functionName: String)
    case invalidNumberOfArguments(functionName: String, expected: Int, got: Int)
    case indexOperatorNotSupported(type: Value.Type)
    case invalidHashKey(type: Value.Type)

    public var description: String {
        let detail: String

        switch self {
        case .unknownInfixOperator(let left, let `operator`, let right):
            detail = "unknown operator - \(left) \(`operator`) \(right)"

        case .unknownPrefixOperator(let `operator`, let right):
            detail = "unknown operator - \(`operator`)\(right)"

        case .undefinedIdentifier(let name):
            detail = "undefined identifier - \(name)"

        case .callNonFunctionValue(let type):
            detail = "call non function value - \(type)"

        case .invalidArgument(let type, let functionName):
            detail = "invalid argument - type: \(type), function name: \(functionName)"

        case .invalidNumberOfArguments(let functionName, let expected, let got):
            detail = "invalid number of arguments - function name: \(functionName), expected: \(expected), got: \(got)"

        case .indexOperatorNotSupported(let type):
            detail = "index operator not supported - type: \(type)"

        case .invalidHashKey(let type):
            detail = "invalid hash key - type: \(type)"
        }

        return "Error: \(detail)"
    }
}

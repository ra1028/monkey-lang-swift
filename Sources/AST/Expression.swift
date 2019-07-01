import Token

public protocol Expression: Node {
    var token: Token { get }
}

public struct IdentifierExpression: Expression, Hashable {
    public var token: Token

    public var description: String {
        return token.literal
    }

    public init(token: Token) {
        self.token = token
    }
}

public struct IntegerExpression: Expression {
    public var token: Token
    public var value: Int64

    public var description: String {
        return token.literal
    }

    public init(token: Token, value: Int64) {
        self.token = token
        self.value = value
    }
}

public struct BooleanExpression: Expression {
    public var token: Token
    public var value: Bool

    public var description: String {
        return token.literal
    }

    public init(token: Token, value: Bool) {
        self.token = token
        self.value = value
    }
}

public struct PrefixExpression: Expression {
    public var token: Token
    public var `operator`: String
    public var right: Expression

    public var description: String {
        return "(\(self.operator)\(right.description))"
    }

    public init(token: Token, operator: String, right: Expression) {
        self.token = token
        self.operator = `operator`
        self.right = right
    }
}

public struct InfixExpression: Expression {
    public var token: Token
    public var left: Expression
    public var `operator`: String
    public var right: Expression

    public var description: String {
        return "(\(left.description) \(self.operator) \(right.description))"
    }

    public init(token: Token, left: Expression, operator: String, right: Expression) {
        self.token = token
        self.left = left
        self.operator = `operator`
        self.right = right
    }
}

public struct IfExpression: Expression {
    public var token: Token
    public var condition: Expression
    public var consequence: BlockStatement
    public var alternative: BlockStatement?

    public var description: String {
        let elseDescription = alternative.map { " else \($0.description)" } ?? ""
        return "if \(condition.description) \(consequence.description)" + elseDescription
    }

    public init(token: Token, condition: Expression, consequence: BlockStatement, alternative: BlockStatement?) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }
}

public struct FunctionExpression: Expression {
    public var token: Token
    public var parameters: [IdentifierExpression]
    public var body: BlockStatement

    public var description: String {
        let parameters = self.parameters.lazy
            .map { $0.description }
            .joined(separator: ", ")
        return "\(token.literal)(\(parameters)) \(body.description)"
    }

    public init(
        token: Token,
        parameters: [IdentifierExpression],
        body: BlockStatement
        ) {
        self.token = token
        self.parameters = parameters
        self.body = body
    }
}

public struct CallExpression: Expression {
    public var token: Token
    public var function: Expression
    public var arguments: [Expression]

    public var description: String {
        let arguments = self.arguments.lazy
            .map { $0.description }
            .joined(separator: ", ")
        return "\(function.description)(\(arguments))"
    }

    public init(
        token: Token,
        function: Expression,
        arguments: [Expression]
        ) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }
}

public struct StringExpression: Expression {
    public var token: Token

    public var description: String {
        return token.literal
    }

    public init(token: Token) {
        self.token = token
    }
}

public struct ArrayExpression: Expression {
    public var token: Token
    public var elements: [Expression]

    public var description: String {
        let elements = self.elements.lazy
            .map { $0.description }
            .joined(separator: ", ")
        return "[\(elements)]"
    }

    public init(token: Token, elements: [Expression]) {
        self.token = token
        self.elements = elements
    }
}

public struct IndexExpression: Expression {
    public var token: Token
    public var left: Expression
    public var index: Expression

    public var description: String {
        return "(\(left.description)[\(index.description)])"
    }

    public init(
        token: Token,
        left: Expression,
        index: Expression
        ) {
        self.token = token
        self.left = left
        self.index = index
    }
}

public struct HashExpression: Expression {
    public var token: Token
    public var pairs: [(key: Expression, value: Expression)]

    public var description: String {
        let pairs = self.pairs.lazy
            .map { "\($0.description): \($1.description)" }
            .joined(separator: ", ")
        return "{\(pairs)}"
    }

    public init(token: Token, pairs: [(key: Expression, value: Expression)]) {
        self.token = token
        self.pairs = pairs
    }
}

import Token

public protocol Statement: Node {
    var token: Token { get }
}

public struct LetStatement: Statement {
    public var token: Token
    public var name: IdentifierExpression
    public var value: Expression

    public var description: String {
        return "\(token.literal) \(name.description) = \(value.description);"
    }

    public init(token: Token, name: IdentifierExpression, value: Expression) {
        self.token = token
        self.name = name
        self.value = value
    }
}

public struct ReturnStatement: Statement {
    public var token: Token
    public var returnValue: Expression

    public var description: String {
        return "\(token.literal) \(returnValue.description);"
    }

    public init(token: Token, returnValue: Expression) {
        self.token = token
        self.returnValue = returnValue
    }
}

public struct ExpressionStatement: Statement {
    public var token: Token
    public var expression: Expression

    public var description: String {
        return expression.description
    }

    public init(token: Token, expression: Expression) {
        self.token = token
        self.expression = expression
    }
}

public struct BlockStatement: Statement {
    public var token: Token
    public var statements: [Statement]

    public var description: String {
        let statementsDescription: String = statements.lazy
            .map { $0.description }
            .joined()
        return "{ \(statementsDescription) }"
    }

    public init(token: Token, statements: [Statement]) {
        self.token = token
        self.statements = statements
    }
}

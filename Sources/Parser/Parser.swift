import Token
import Lexer
import AST

public struct Parser {
    public var lexer: Lexer
    public var currentToken: Token
    public var peekToken: Token
    public var errors: [ParseError]

    public init(input: String) {
        let lexer = Lexer(input: input)
        self.init(lexer: lexer)
    }

    public init(lexer: Lexer) {
        self.lexer = lexer
        self.currentToken = self.lexer.nextToken()
        self.peekToken = self.lexer.nextToken()
        self.errors = []
    }

    public mutating func parse() -> Program {
        var statements = [Statement]()

        while currentToken.kind != .eof {
            if let statement = parseStatement() {
                statements.append(statement)
            }

            nextToken()
        }

        return Program(statements: statements)
    }
}

private extension Parser {
    mutating func nextToken() {
        currentToken = peekToken
        peekToken = lexer.nextToken()
    }

    mutating func parseStatement() -> Statement? {
        switch currentToken.kind {
        case .let:
            return parseLetStatement()

        case .return:
            return parseReturnStatement()

        default:
            return parseExpressionStatement()
        }
    }

    mutating func parseLetStatement() -> LetStatement? {
        let token = currentToken

        guard expectPeek(kind: .identifier) else {
            return nil
        }

        let name = parseIdentifierExpression()

        guard expectPeek(kind: .assign) else {
            return nil
        }

        nextToken()

        guard let value = parseExpression(precendence: .lowest) else {
            errors.append(.initialValueNotFound(name: name))
            return nil
        }

        if currentToken.kind == .semicolon {
            nextToken()
        }

        return LetStatement(token: token, name: name, value: value)
    }

    mutating func parseReturnStatement() -> ReturnStatement? {
        let token = currentToken

        nextToken()

        guard let returnValue = parseExpression(precendence: .lowest) else {
            errors.append(.returnValueNotFound)
            return nil
        }

        if currentToken.kind == .semicolon {
            nextToken()
        }

        return ReturnStatement(token: token, returnValue: returnValue)
    }

    mutating func parseExpressionStatement() -> ExpressionStatement? {
        let token = currentToken
        let expression = parseExpression(precendence: .lowest)

        if peekToken.kind == .semicolon {
            nextToken()
        }

        return expression.map { expression in
            ExpressionStatement(token: token, expression: expression)
        }
    }

    mutating func parseBlockStatement() -> BlockStatement? {
        let token = currentToken
        var statements = [Statement]()

        nextToken()

        while currentToken.kind != .rBrace && currentToken.kind != .eof {
            if let statement = parseStatement() {
                statements.append(statement)
            }

            nextToken()
        }

        return BlockStatement(token: token, statements: statements)
    }

    mutating func parseExpression(precendence: Precedence) -> Expression? {
        var expression: Expression?

        switch currentToken.kind {
        case .identifier:
            expression = parseIdentifierExpression()

        case .int:
            expression = parseIntegerExpression()

        case .string:
            expression = parseStringExpression()

        case .true, .false:
            expression = parseBooleanExpression()

        case .bang, .minus:
            expression = parsePrefixExpression()

        case .lParen:
            expression = parseGroupedExpreession()

        case .if:
            expression = parseIfExpression()

        case .function:
            expression = parseFunctionExpression()

        case .lBracket:
            expression = parseArrayExpression()

        case .lBrace:
            expression = parseHashExpression()

        default:
            return nil
        }

        while let left = expression, peekToken.kind != .semicolon && precendence < peekToken.kind.precedence {
            switch peekToken.kind {
            case .plus,
                 .minus,
                 .slash,
                 .asterisk,
                 .eq,
                 .notEq,
                 .lt,
                 .gt:
                nextToken()
                expression = parseInfixExpression(left: left)

            case .lParen:
                nextToken()
                expression = parseCallExpression(function: left)

            case .lBracket:
                nextToken()
                expression = parseIndexExpression(left: left)

            default:
                return expression
            }
        }

        return expression
    }

    mutating func parseGroupedExpreession() -> Expression? {
        nextToken()

        let expression = parseExpression(precendence: .lowest)

        guard expectPeek(kind: .rParen) else {
            return nil
        }

        return expression
    }

    mutating func parseIdentifierExpression() -> IdentifierExpression {
        return IdentifierExpression(token: currentToken)
    }

    mutating func parseIntegerExpression() -> IntegerExpression? {
        let token = currentToken

        guard let value = Int64(token.literal) else {
            errors.append(.illegalCharacterFoundInIntegerLiteral(token.literal))
            return nil
        }

        return IntegerExpression(token: token, value: value)
    }

    mutating func parseStringExpression() -> StringExpression {
        return StringExpression(token: currentToken)
    }

    mutating func parseBooleanExpression() -> BooleanExpression? {
        let token = currentToken

        guard let value = Bool(token.literal) else {
            errors.append(.illegalCharacterFoundInBooleanLiteral(token.literal))
            return nil
        }

        return BooleanExpression(token: token, value: value)
    }

    mutating func parsePrefixExpression() -> PrefixExpression? {
        let token = currentToken
        let `operator` = token.literal

        nextToken()

        guard let right = parseExpression(precendence: .prefix) else {
            errors.append(.prefixOperatorRightValueNotFound(operator: `operator`))
            return nil
        }

        return PrefixExpression(token: token, operator: `operator`, right: right)
    }

    mutating func parseInfixExpression(left: Expression) -> InfixExpression? {
        let token = currentToken
        let `operator` = token.literal
        let precedence = currentToken.kind.precedence

        nextToken()

        guard let right = parseExpression(precendence: precedence) else {
            errors.append(.infixOperatorRightValueNotFound(operator: `operator`))
            return nil
        }

        return InfixExpression(token: token, left: left, operator: `operator`, right: right)
    }

    mutating func parseIfExpression() -> IfExpression? {
        let token = currentToken

        guard expectPeek(kind: .lParen) else {
            return nil
        }

        nextToken()

        guard let condition = parseExpression(precendence: .lowest) else {
            return nil
        }

        guard expectPeek(kind: .rParen) else {
            return nil
        }

        guard expectPeek(kind: .lBrace) else {
            return nil
        }

        guard let consequence = parseBlockStatement() else {
            return nil
        }

        let alternative: BlockStatement?

        if peekToken.kind == .else {
            nextToken()

            alternative = expectPeek(kind: .lBrace) ? parseBlockStatement() : nil
        }
        else {
            alternative = nil
        }

        return IfExpression(
            token: token,
            condition: condition,
            consequence: consequence,
            alternative: alternative
        )
    }

    mutating func parseFunctionExpression() -> FunctionExpression? {
        let token = currentToken

        guard expectPeek(kind: .lParen) else {
            return nil
        }

        let parameters = parseFunctionParameterExpressions()

        guard expectPeek(kind: .lBrace) else {
            return nil
        }

        guard let body = parseBlockStatement() else {
            return nil
        }

        return FunctionExpression(
            token: token,
            parameters: parameters,
            body: body
        )
    }

    mutating func parseFunctionParameterExpressions() -> [IdentifierExpression] {
        guard peekToken.kind != .rParen else {
            nextToken()
            return []
        }

        nextToken()

        var parameters = [parseIdentifierExpression()]

        while peekToken.kind == .comma {
            nextToken()
            nextToken()
            parameters.append(parseIdentifierExpression())
        }

        guard expectPeek(kind: .rParen) else {
            return []
        }

        return parameters
    }

    mutating func parseCallExpression(function: Expression) -> CallExpression {
        let token = currentToken
        let arguments = parseExpressionList(endTokenKind: .rParen)
        return CallExpression(token: token, function: function, arguments: arguments)
    }

    mutating func parseArrayExpression() -> ArrayExpression {
        let token = currentToken
        let elements = parseExpressionList(endTokenKind: .rBracket)
        return ArrayExpression(token: token, elements: elements)
    }

    mutating func parseExpressionList(endTokenKind: TokenKind) -> [Expression] {
        guard peekToken.kind != endTokenKind else {
            nextToken()
            return []
        }

        nextToken()

        guard let firstArgument = parseExpression(precendence: .lowest) else {
            return []
        }

        var arguments = [firstArgument]

        while peekToken.kind == .comma {
            nextToken()
            nextToken()

            if let expression = parseExpression(precendence: .lowest) {
                arguments.append(expression)
            }
        }

        guard expectPeek(kind: endTokenKind) else {
            return []
        }

        return arguments
    }

    mutating func parseIndexExpression(left: Expression) -> IndexExpression? {
        let token = currentToken

        nextToken()

        guard let index = parseExpression(precendence: .lowest) else {
            return nil
        }

        if !expectPeek(kind: .rBracket) {
            return nil
        }

        return IndexExpression(token: token, left: left, index: index)
    }

    mutating func parseHashExpression() -> HashExpression? {
        let token = currentToken
        var pairs = [(key: Expression, value: Expression)]()

        while peekToken.kind != .rBrace {
            nextToken()

            guard let key = parseExpression(precendence: .lowest) else {
                return nil
            }

            guard expectPeek(kind: .colon) else {
                return nil
            }

            nextToken()

            guard let value = parseExpression(precendence: .lowest) else {
                return nil
            }

            pairs.append((key, value))

            if peekToken.kind != .rBrace && !expectPeek(kind: .comma) {
                return nil
            }
        }

        if !expectPeek(kind: .rBrace) {
            return nil
        }

        return HashExpression(token: token, pairs: pairs)
    }

    mutating func expectPeek(kind: TokenKind) -> Bool {
        if peekToken.kind == kind {
            nextToken()
            return true
        }
        else {
            errors.append(.invalidTokenFound(expected: kind, got: peekToken.kind))
            return false
        }
    }
}

private extension TokenKind {
    var precedence: Precedence {
        switch self {
        case .eq, .notEq:
            return .equals

        case .lt, .gt:
            return .lessGreater

        case .plus, .minus:
            return .sum

        case .slash, .asterisk:
            return .product

        case .lParen:
            return .call

        case .lBracket:
            return .index

        default:
            return .lowest
        }
    }
}

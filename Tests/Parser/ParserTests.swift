import XCTest
import Token
import AST
@testable import Parser

final class ParserTests: XCTestCase {
    func testLetStatement() {
        let tests: [(input: String, expectedIdentifier: String, expectedValue: Any)] = [
            ("let x = 5;", "x", 5),
            ("let y = true;", "y", true),
            ("let foobar = y;", "foobar", "y")
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let letStatement: LetStatement = castOrAssert(value: program.statements[0])

            XCTAssertEqual(letStatement.token.literal, "let")
            XCTAssertEqual(letStatement.name.token.literal, test.expectedIdentifier)
            XCTAssertCorrectLiteral(expression: letStatement.value, expected: test.expectedValue)
        }
    }

    func testReturnStatement() {
        let tests: [(input: String, expectedReturnValue: Any)] = [
            ("return 5;", 5),
            ("return true;", true),
            ("return foobar;", "foobar")
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let returnStatement: ReturnStatement = castOrAssert(value: program.statements[0])

            XCTAssertEqual(returnStatement.token.literal, "return")
            XCTAssertCorrectLiteral(expression: returnStatement.returnValue, expected: test.expectedReturnValue)
        }
    }

    func testDescription() {
        let program = Program(
            statements: [
                LetStatement(
                    token: Token(kind: .let, literal: "let"),
                    name: IdentifierExpression(
                        token: Token(kind: .identifier, literal: "myVar")
                    ),
                    value: IdentifierExpression(
                        token: Token(kind: .identifier, literal: "anotherVar")
                    )
                )
            ]
        )

        XCTAssertEqual(program.description, "let myVar = anotherVar;")
    }

    func testIdentifierExpression() {
        let input = "foobar;"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        XCTAssertCorrectLiteral(expression: expressionStatement.expression, expected: "foobar")
    }

    func testIntegerLiteralExpression() {
        let input = "5;"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        XCTAssertCorrectLiteral(expression: expressionStatement.expression, expected: 5)
    }

    func testBooleanExpression() {
        let input = "true;"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        XCTAssertCorrectLiteral(expression: expressionStatement.expression, expected: true)
    }

    func testPrefixExpression() {
        let tests: [(input: String, operator: String, value: Int64)] = [
            ("!5;", "!", 5),
            ("-15;", "-", 15)
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
            let prefixExpression: PrefixExpression = castOrAssert(value: expressionStatement.expression)
            let integerExpression: IntegerExpression = castOrAssert(value: prefixExpression.right)

            XCTAssertEqual(integerExpression.value, test.value)
            XCTAssertEqual(integerExpression.token.literal, String(test.value))
        }
    }

    func testInfixExpression() {
        let tests: [(input: String, leftValue: Any, operator: String, rightValue: Any)] = [
            ("5 + 5;", 5, "+", 5),
            ("5 - 5;", 5, "-", 5),
            ("5 * 5;", 5, "*", 5),
            ("5 / 5;", 5, "/", 5),
            ("5 > 5;", 5, ">", 5),
            ("5 < 5;", 5, "<", 5),
            ("5 == 5;", 5, "==", 5),
            ("5 != 5;", 5, "!=", 5),
            ("true == true", true, "==", true),
            ("true != false", true, "!=", false),
            ("false == false", false, "==", false)
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
            XCTAssertCorrectInfix(
                expression: expressionStatement.expression,
                expectedLeft: test.leftValue,
                expectedOperator: test.operator,
                exprectedRight: test.rightValue
            )
        }
    }

    func testIfExpression() {
        let input = "if (x < y) { x }"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        let ifExpression: IfExpression = castOrAssert(value: expressionStatement.expression)
        let consequence: ExpressionStatement = castOrAssert(value: ifExpression.consequence.statements.first)

        XCTAssertEqual(ifExpression.consequence.statements.count, 1)
        XCTAssertNil(ifExpression.alternative)
        XCTAssertCorrectLiteral(expression: consequence.expression, expected: "x")
        XCTAssertCorrectInfix(
            expression: ifExpression.condition,
            expectedLeft: "x",
            expectedOperator: "<",
            exprectedRight: "y"
        )
    }

    func testIfElseExpression() {
        let input = "if (x < y) { x } else { y }"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        let ifExpression: IfExpression = castOrAssert(value: expressionStatement.expression)
        let consequence: ExpressionStatement = castOrAssert(value: ifExpression.consequence.statements.first)
        let alternative: ExpressionStatement = castOrAssert(value: ifExpression.alternative?.statements.first)

        XCTAssertEqual(ifExpression.consequence.statements.count, 1)
        XCTAssertNotNil(ifExpression.alternative)
        XCTAssertCorrectLiteral(expression: consequence.expression, expected: "x")
        XCTAssertCorrectLiteral(expression: alternative.expression, expected: "y")
        XCTAssertCorrectInfix(
            expression: ifExpression.condition,
            expectedLeft: "x",
            expectedOperator: "<",
            exprectedRight: "y"
        )
    }

    func testFunctionExpression() {
        let input = "fn(x, y) { x + y; }"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
        let functionExpression: FunctionExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(functionExpression.parameters.count, 2)
        XCTAssertEqual(functionExpression.body.statements.count, 1)
        XCTAssertCorrectLiteral(expression: functionExpression.parameters[0], expected: "x")
        XCTAssertCorrectLiteral(expression: functionExpression.parameters[1], expected: "y")

        let bodyExpressionStatement: ExpressionStatement = castOrAssert(value: functionExpression.body.statements[0])

        XCTAssertCorrectInfix(
            expression: bodyExpressionStatement.expression,
            expectedLeft: "x",
            expectedOperator: "+",
            exprectedRight: "y"
        )
    }

    func textFunctionParamerterExpressions() {
        let tests: [(input: String, expected: [String])] = [
            ("fn() {};", []),
            ("fn(x) {x};", ["x"]),
            ("fn(x, y, z)", ["x", "y", "z"])
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements.first)
            let functionExpression: FunctionExpression = castOrAssert(value: expressionStatement.expression)

            XCTAssertEqual(functionExpression.parameters.map { $0.token.literal }, test.expected)

            for (parameter, expected) in zip(functionExpression.parameters, test.expected) {
                XCTAssertCorrectLiteral(expression: parameter, expected: expected)
            }
        }
    }

    func testCallExpression() {
        let input = "add(1, 2 * 3, 4 + 5);"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let callExpression: CallExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertCorrectLiteral(expression: callExpression.function, expected: "add")
        XCTAssertEqual(callExpression.arguments.count, 3)
        XCTAssertCorrectLiteral(expression: callExpression.arguments[0], expected: 1)
        XCTAssertCorrectInfix(
            expression: callExpression.arguments[1],
            expectedLeft: 2,
            expectedOperator: "*",
            exprectedRight: 3
        )
        XCTAssertCorrectInfix(
            expression: callExpression.arguments[2],
            expectedLeft: 4,
            expectedOperator: "+",
            exprectedRight: 5
        )
    }

    func testCallExpressionArguments() {
        let tests: [(input: String, expectedIdentifier: String, expectedArguments: [String])] = [
            ("add();", "add", []),
            ("add(1);", "add", ["1"]),
            ("add(1, 2 * 3, 4 + 5);", "add", ["1", "(2 * 3)", "(4 + 5)"])
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(program.statements.count, 1)

            let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
            let callExpression: CallExpression = castOrAssert(value: expressionStatement.expression)

            XCTAssertCorrectLiteral(expression: callExpression.function, expected: test.expectedIdentifier)
            XCTAssertEqual(callExpression.arguments.map { $0.description }, test.expectedArguments)

            for (argument, expected) in zip(callExpression.arguments, test.expectedArguments) {
                XCTAssertEqual(argument.description, expected)
            }
        }
    }

    func testStringExpression() {
        let input = "\"hello world\""
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let stringExpression: StringExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(stringExpression.token.literal, "hello world")
    }

    func testArrayExpression() {
        let input = "[1, 2 * 2, 3 + 3]"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let arrayExpression: ArrayExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(arrayExpression.elements.count, 3)
        XCTAssertCorrectLiteral(expression: arrayExpression.elements[0], expected: 1)
        XCTAssertCorrectInfix(
            expression: arrayExpression.elements[1],
            expectedLeft: 2,
            expectedOperator: "*",
            exprectedRight: 2
        )
        XCTAssertCorrectInfix(
            expression: arrayExpression.elements[2],
            expectedLeft: 3,
            expectedOperator: "+",
            exprectedRight: 3
        )
    }

    func testIndexExpression() {
        let input = "array[1 + 1]"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let indexExpression: IndexExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertCorrectLiteral(expression: indexExpression.left, expected: "array")
        XCTAssertCorrectInfix(
            expression: indexExpression.index,
            expectedLeft: 1,
            expectedOperator: "+",
            exprectedRight: 1
        )
    }

    func testHashExpressionWithStringKeys() {
        let input = #"{"one": 1, "two": 2, "three": 3}"#
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let hashExpression: HashExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(hashExpression.pairs.count, 3)

        let expected = [
            "one": 1,
            "two": 2,
            "three": 3
        ]

        for (key, value) in hashExpression.pairs {
            let key: StringExpression = castOrAssert(value: key)
            guard let expectedValue = expected[key.token.literal] else {
                XCTFail("Invalid key literal")
                return
            }
            XCTAssertCorrectLiteral(expression: value, expected: expectedValue)
        }
    }

    func testEmptyHashExpression() {
        let input = "{}"
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let hashExpression: HashExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(hashExpression.pairs.count, 0)
    }

    func testHashExpressionWithExpressionValues() {
        let input = #"{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}"#
        var parser = Parser(input: input)
        let program = parser.parse()

        XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
        XCTAssertEqual(program.statements.count, 1)

        let expressionStatement: ExpressionStatement = castOrAssert(value: program.statements[0])
        let hashExpression: HashExpression = castOrAssert(value: expressionStatement.expression)

        XCTAssertEqual(hashExpression.pairs.count, 3)

        let tests: [String: (Expression) -> Void] = [
            "one": {
                XCTAssertCorrectInfix(expression: $0, expectedLeft: 0, expectedOperator: "+", exprectedRight: 1)
            },
            "two": {
                XCTAssertCorrectInfix(expression: $0, expectedLeft: 10, expectedOperator: "-", exprectedRight: 8)
            },
            "three": {
                XCTAssertCorrectInfix(expression: $0, expectedLeft: 15, expectedOperator: "/", exprectedRight: 5)
            }
        ]

        for (key, value) in hashExpression.pairs {
            let key: StringExpression = castOrAssert(value: key)
            guard let test = tests[key.token.literal] else {
                XCTFail("Invalid key literal")
                return
            }
            test(value)
        }
    }

    func testOperatorPrecedence() {
        let tests: [(input: String, expected: String)] = [
            ("-a * b", "((-a) * b)"),
            ("!-a", "(!(-a))"),
            ("a + b + c", "((a + b) + c)"),
            ("a + b - c", "((a + b) - c)"),
            ("a * b * c", "((a * b) * c)"),
            ("a * b / c", "((a * b) / c)"),
            ("a + b / c", "(a + (b / c))"),
            ("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
            ("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"),
            ("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
            ("5 > 4 != 3 < 4", "((5 > 4) != (3 < 4))"),
            ("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
            ("true", "true"),
            ("false", "false"),
            ("3 > 5 == false", "((3 > 5) == false)"),
            ("3 < 5 == true", "((3 < 5) == true)"),
            ("1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"),
            ("(5 + 5) * 2", "((5 + 5) * 2)"),
            ("2 / (5 + 5)", "(2 / (5 + 5))"),
            ("-(5 + 5)", "(-(5 + 5))"),
            ("!(true == true)", "(!(true == true))"),
            ("a + add(b * c) + d", "((a + add((b * c))) + d)"),
            ("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
            ("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))"),
            ("a * [1, 2, 3, 4][b * c] * d", "((a * ([1, 2, 3, 4][(b * c)])) * d)"),
            ("add(a * b[2], b[1], 2 * [1, 2][1])", "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))")
        ]

        for test in tests {
            var parser = Parser(input: test.input)
            let program = parser.parse()
            let actual = program.description

            XCTAssertTrue(parser.errors.isEmpty, "\(parser.errors)")
            XCTAssertEqual(actual, test.expected)
        }
    }
}

private func XCTAssertCorrectLiteral<T>(expression: Expression, expected: T) {
    func assertCorrectBoolean(expression: Expression, expected: Bool) {
        let booleanExpression: BooleanExpression = castOrAssert(value: expression)
        XCTAssertEqual(booleanExpression.value, expected)
        XCTAssertEqual(booleanExpression.token.literal, String(expected))
    }

    func assertCorrectIntegerLiteral(expression: Expression, expected: Int64) {
        let integerExpression: IntegerExpression = castOrAssert(value: expression)
        XCTAssertEqual(integerExpression.value, expected)
        XCTAssertEqual(integerExpression.token.literal, String(expected))
    }

    func assertCorrectIdentifier(expression: Expression, expected: String) {
        let identifierExpression: IdentifierExpression = castOrAssert(value: expression)
        XCTAssertEqual(identifierExpression.token.literal, expected)
    }


    if let expected = expected as? Bool {
        assertCorrectBoolean(expression: expression, expected: expected)
    }
    else if let expected = expected as? Int {
        assertCorrectIntegerLiteral(expression: expression, expected: Int64(expected))
    }
    else if let expected = expected as? Int64 {
        assertCorrectIntegerLiteral(expression: expression, expected: expected)
    }
    else if let expected = expected as? String {
        assertCorrectIdentifier(expression: expression, expected: expected)
    }
    else {
        XCTFail("Unsupported literal type. expression: \(expression), expected: \(expected)")
    }
}

private func XCTAssertCorrectInfix<L, R>(
    expression: Expression,
    expectedLeft: L,
    expectedOperator: String,
    exprectedRight: R) {
    let infixExpression: InfixExpression = castOrAssert(value: expression)
    XCTAssertCorrectLiteral(expression: infixExpression.left, expected: expectedLeft)
    XCTAssertEqual(infixExpression.operator, expectedOperator)
    XCTAssertCorrectLiteral(expression: infixExpression.right, expected: exprectedRight)
}

private func castOrAssert<T, U>(value: T, as type: U.Type = U.self) -> U {
    guard let castValue = value as? U else {
        XCTFail("Failed to cast \(value) to type \(U.self)")
        fatalError()
    }
    return castValue
}

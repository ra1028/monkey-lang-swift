import XCTest
import Parser
@testable import Evaluator

final class EvaluatorTests: XCTestCase {
    func testInteger() {
        let tests: [(input: String, expected: Int64)] = [
            ("5", 5),
            ("10", 10),
            ("-5", -5),
            ("-10", -10),
            ("5 + 5 + 5 + 5 - 10", 10),
            ("2 * 2 * 2 * 2 * 2", 32),
            ("-50 + 100 + -50", 0),
            ("5 * 2 + 10", 20),
            ("5 + 2 * 10", 25),
            ("20 + 2 * -10", 0),
            ("50 / 2 * 2 + 10", 60),
            ("2 * (5 + 10)", 30),
            ("3 * 3 * 3 + 10", 37),
            ("3 * (3 * 3) + 10", 37),
            ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testBoolean() {
        let tests: [(input: String, expected: Bool)] = [
            ("true", true),
            ("false", false),
            ("1 < 2", true),
            ("1 > 2", false),
            ("1 < 1", false),
            ("1 > 1", false),
            ("1 == 1", true),
            ("1 != 1", false),
            ("1 == 2", false),
            ("1 != 2", true),
            ("true == true", true),
            ("false == false", true),
            ("true == false", false),
            ("true != false", true),
            ("false != true", true),
            ("(1 < 2) == true", true),
            ("(1 < 2) == false", false),
            ("(1 > 2) == true", false),
            ("(1 > 2) == false", true)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testBangOperator() {
        let tests: [(input: String, expected: Bool)] = [
            ("!true", false),
            ("!false", true),
            ("!5", false),
            ("!!true", true),
            ("!!false", false),
            ("!!5", true)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testIfElse() {
        let tests: [(input: String, expected: Int64?)] = [
            ("if (true) { 10 }", 10),
            ("if (false) { 10 }", nil),
            ("if (1) { 10 }", 10),
            ("if (1 < 2) { 10 }", 10),
            ("if (1 > 2) { 10 }", nil),
            ("if (1 > 2) { 10 } else { 20 }", 20),
            ("if (1 < 2) { 10 } else { 20 }", 10)
        ]

        for test in tests {
            let value = evaluate(input: test.input)
            if let expected = test.expected {
                XCTAssertValueEqual(value, expected: expected)
            }
            else {
                XCTAssertNull(value)
            }
        }
    }

    func testReturn() {
        let tests: [(input: String, expected: Int64)] = [
            ("return 10;", 10),
            ("return 10; 9;", 10),
            ("return 2 * 5; 9;", 10),
            ("9; return 2 * 5; 9;", 10),
            ("""
             if (10 > 1) {
               if (10 > 1) {
                 return 10;
               }
             }
             return 1;
             """, 10)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testError() {
        let tests: [(input: String, expected: Error)] = [
            (
                "5 + true;",
                .unknownInfixOperator(left: Integer.self, operator: "+", right: Boolean.self)
            ),
            (
                "5 + true; 5;",
                .unknownInfixOperator(left: Integer.self, operator: "+", right: Boolean.self)
            ),
            (
                "-true",
                .unknownPrefixOperator(operator: "-", right: Boolean.self)
            ),
            (
                "true + false;",
                .unknownInfixOperator(left: Boolean.self, operator: "+", right: Boolean.self)
            ),
            (
                "5; true + false; 5",
                .unknownInfixOperator(left: Boolean.self, operator: "+", right: Boolean.self)
            ),
            (
                "if (10 > 1) { true + false; }",
                .unknownInfixOperator(left: Boolean.self, operator: "+", right: Boolean.self)
            ),
            (
                """
                if (10 > 1) {
                  if (10 > 1) {
                    return true + false;
                  }
                  return 1;
                }
                """,
                .unknownInfixOperator(left: Boolean.self, operator: "+", right: Boolean.self)
            ),
            (
                "foobar",
                .undefinedIdentifier(name: "foobar")
            ),
            (
                "\"Hello\" - \"World\"",
                .unknownInfixOperator(left: StringValue.self, operator: "-", right: StringValue.self)
            ),
            (
                #"{"name": "monkey"}[fn(x) { x }]"#,
                .invalidHashKey(type: Function.self)
            )
        ]

        for test in tests {
            let value = evaluate(input: test.input)

            guard let error = value as? Error else {
                XCTFail("Value is not Error")
                break
            }

            XCTAssertEqual(error.description, test.expected.description)
        }
    }

    func testLet() {
        let tests: [(input: String, expected: Int64)] = [
            ("let a = 5; a;", 5),
            ("let a = 5 * 5; a;", 25),
            ("let a = 5, let b = a; b;", 5),
            ("let a = 5, let b = a; let c = a + b + 5; c;", 15)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testFunction() {
        let input = "fn(x) { x + 2; };"
        let value = evaluate(input: input)

        guard let function = value as? Function else {
            XCTFail("Value is not Function")
            return
        }

        XCTAssertEqual(function.expression.parameters.count, 1)
        XCTAssertEqual(function.expression.parameters[0].token.literal, "x")
        XCTAssertEqual(function.expression.body.description, "{ (x + 2) }")
    }

    func testCall() {
        let tests: [(input: String, expected: Int64)] = [
            ("let identity = fn(x) { x; }; identity(5);", 5),
            ("let identity = fn(x) { return x; }; identity(5);", 5),
            ("let double = fn(x) { x * 2; }; double(5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
            ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
            ("fn(x) { x; }(5)", 5)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testClosure() {
        let input = """
        let newAdder = fn(x) {
          fn(y) { x + y };
        }
        let addTwo = newAdder(2);
        addTwo(2)
        """

        XCTAssertValueEqual(evaluate(input: input), expected: 4)
    }

    func testString() {
        let tests: [(input: String, expected: Any)] = [
            ("\"Hello World!\"", "Hello World!"),
            ("\"Hello\" + \" \" + \"World!\"", "Hello World!"),
            ("\"Hello\" == \"Hello\"", true),
            ("\"Hello\" == \"World\"", false),
            ("\"Hello\" != \"Hello\"", false),
            ("\"Hello\" != \"World\"", true)
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testArray() {
        let input = "[1, 2 * 2, 3 + 3]"
        let value = evaluate(input: input)

        guard let array = value as? ArrayValue else {
            XCTFail("Value is not ArrayValue")
            return
        }

        XCTAssertEqual(array.elements.count, 3)
        XCTAssertValueEqual(array.elements[0], expected: 1)
        XCTAssertValueEqual(array.elements[1], expected: 4)
        XCTAssertValueEqual(array.elements[2], expected: 6)
    }

    func testArrayIndex() {
        let tests: [(input: String, expected: Any?)] = [
            ("[1, 2, 3][0]", 1),
            ("[1, 2, 3][1]", 2),
            ("[1, 2, 3][2]", 3),
            ("let i = 0; [1][i];", 1),
            ("[1, 2, 3][1 + 1]", 3),
            ("let array = [1, 2, 3]; array[2];", 3),
            ("let array = [1, 2, 3]; array[0] + array[1] + array[2];", 6),
            ("let array = [1, 2, 3]; let i = array[0]; array[i]", 2),
            ("[1, 2, 3][3]", nil),
            ("[1, 2, 3][-1]", nil)
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let expected = test.expected {
                XCTAssertValueEqual(evaluated, expected: expected)
            }
            else {
                XCTAssertNull(evaluated)
            }
        }
    }

    func testHash() {
        let input = """
        let two = "two";
        {
          "one": 10 - 9,
          "two": 1 + 1,
          "thr" + "ee": 6/ 2,
          4: 4,
          true: 5,
          false: 6
        }
        """

        let evaluated = evaluate(input: input)

        guard let hash = evaluated as? Hash else {
            XCTFail("evaluated is not Hash")
            return
        }

        let expected: [AnyHashable: Int] = [
            StringValue(value: "one"): 1,
            StringValue(value: "two"): 2,
            StringValue(value: "three"): 3,
            Integer(value: 4): 4,
            Boolean(value: true): 5,
            Boolean(value: false): 6
        ]

        for (key, value) in hash.pairs {
            guard let expectedValue = expected[key] else {
                XCTFail("Invalid hash key")
                return
            }

            XCTAssertValueEqual(value, expected: expectedValue)
        }
    }

    func testHashIndex() {
        let tests: [(input: String, expected: Any?)] = [
            (#"{"foo": 5}["foo"]"#, 5),
            (#"{"foo": 5}["bar"]"#, nil),
            (#"let key = "foo"; {"foo": 5}[key]"#, 5),
            (#"{}["foo"]"#, nil),
            (#"{5: 5}[5]"#, 5),
            (#"{true: 5}[true]"#, 5),
            (#"{false: 5}[false]"#, 5)
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let expected = test.expected {
                XCTAssertValueEqual(evaluated, expected: expected)
            }
            else {
                XCTAssertNull(evaluated)
            }
        }
    }

    func testBuiltinLen() {
        let tests: [(input: String, expected: Any)] = [
            (#"len("")"#, 0),
            (#"len("four")"#, 4),
            (#"len("hello world")"#, 11),
            (#"len([0, 1, 2])"#, 3),
            ("len(1)", Error.invalidArgument(type: Integer.self, functionName: "len")),
            (#"len("one", "two")"#, Error.invalidNumberOfArguments(functionName: "len", expected: 1, got: 2))
        ]

        for test in tests {
            XCTAssertValueEqual(evaluate(input: test.input), expected: test.expected)
        }
    }

    func testBuiltinFirst() {
        let tests: [(input: String, expected: Any?)] = [
            (#"first([])"#, nil),
            (#"first([0, 1, 2])"#, 0),
            (#"first("hello world")"#, Error.invalidArgument(type: StringValue.self, functionName: "first")),
            (#"first([0, 1], [2, 3])"#, Error.invalidNumberOfArguments(functionName: "first", expected: 1, got: 2))
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let expected = test.expected {
                XCTAssertValueEqual(evaluated, expected: expected)
            }
            else {
                XCTAssertNull(evaluated)
            }
        }
    }

    func testBuiltinLast() {
        let tests: [(input: String, expected: Any?)] = [
            (#"last([])"#, nil),
            (#"last([0, 1, 2])"#, 2),
            (#"last("hello world")"#, Error.invalidArgument(type: StringValue.self, functionName: "last")),
            (#"last([0, 1], [2, 3])"#, Error.invalidNumberOfArguments(functionName: "last", expected: 1, got: 2))
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let expected = test.expected {
                XCTAssertValueEqual(evaluated, expected: expected)
            }
            else {
                XCTAssertNull(evaluated)
            }
        }
    }

    func testBuiltinRest() {
        let tests: [(input: String, expected: Any)] = [
            (#"rest([])"#, []),
            (#"rest([0, 1, 2])"#, [1, 2]),
            (#"rest("hello world")"#, Error.invalidArgument(type: StringValue.self, functionName: "rest")),
            (#"rest([0, 1], [2, 3])"#, Error.invalidNumberOfArguments(functionName: "rest", expected: 1, got: 2))
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let array = evaluated as? ArrayValue, let expected = test.expected as? Array<Int> {
                XCTAssertEqual(array.elements.count, expected.count)
            }
            else {
                XCTAssertValueEqual(evaluated, expected: test.expected)
            }
        }
    }

    func testBuiltinPush() {
        let tests: [(input: String, expected: Any)] = [
            (#"push([], 1)"#, [1]),
            (#"push([0, 1], 2)"#, [0, 1, 2]),
            (#"push("hello world", 1)"#, Error.invalidArgument(type: StringValue.self, functionName: "push")),
            (#"push([0, 1], 2, 3)"#, Error.invalidNumberOfArguments(functionName: "push", expected: 2, got: 3))
        ]

        for test in tests {
            let evaluated = evaluate(input: test.input)

            if let array = evaluated as? ArrayValue, let expected = test.expected as? Array<Int> {
                XCTAssertEqual(array.elements.count, expected.count)
            }
            else {
                XCTAssertValueEqual(evaluated, expected: test.expected)
            }
        }
    }
}

func XCTAssertValueEqual<T>(_ value: Value?, expected: T) {
    func assertIntegerEqual(_ value: Value?, expected: Int64) {
        guard let integer = value as? Integer else {
            XCTFail("Value is not Integer")
            return
        }

        XCTAssertEqual(integer.value, expected)
    }

    func assertStringEqual(_ value: Value?, expected: String) {
        guard let string = value as? StringValue else {
            XCTFail("Value is not StringValue")
            return
        }

        XCTAssertEqual(string.value, expected)
    }

    func assertBooleanEqual(_ value: Value?, expected: Bool) {
        guard let boolean = value as? Boolean else {
            XCTFail("Value is not Boolean")
            return
        }

        XCTAssertEqual(boolean.value, expected)
    }

    func assertErrorEqual(_ value: Value?, expected: Error) {
        guard let error = value as? Error else {
            XCTFail("Value is not Error")
            return
        }

        XCTAssertEqual(error.description, expected.description)
    }

    if let expected = expected as? Int {
        assertIntegerEqual(value, expected: Int64(expected))
    }
    else if let expected = expected as? Int64 {
        assertIntegerEqual(value, expected: expected)
    }
    else if let expected = expected as? String {
        assertStringEqual(value, expected: expected)
    }
    else if let expected = expected as? Bool {
        assertBooleanEqual(value, expected: expected)
    }
    else if let expected = expected as? Error {
        assertErrorEqual(value, expected: expected)
    }
    else {
        XCTFail("Unsupported literal type. value: \(value.debugDescription), expected: \(expected)")
    }
}

private func XCTAssertNull(_ value: Value?) {
    XCTAssertTrue(value is Null)
}

private func evaluate(input: String) -> Value? {
    var parser = Parser(input: input)
    let program = parser.parse()
    let evaluator = Evaluator(program: program)
    let environment = Environment()
    return evaluator.evaluate(environment: environment)
}

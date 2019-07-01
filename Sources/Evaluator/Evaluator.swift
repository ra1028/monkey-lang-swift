import AST

public struct Evaluator {
    public var program: Program

    public init(program: Program) {
        self.program = program
    }

    public func evaluate(environment: Environment) -> Value? {
        var result: Value?

        for statement in program.statements {
            result = evaluate(statement: statement, environment: environment)

            if let returnValue = result as? ReturnValue {
                result = returnValue.value
                break
            }
            else if result?.isError ?? false {
                break
            }
        }

        return result
    }
}

private extension Evaluator {
    func evaluate(statement: Statement, environment: Environment) -> Value? {
        switch statement {
        case let statement as ExpressionStatement:
            return evaluate(expression: statement.expression, environment: environment)

        case let statement as BlockStatement:
            return evaluateBlock(statements: statement.statements, environment: environment)

        case let statement as ReturnStatement:
            return evaluateReturnValue(statement: statement, environment: environment)

        case let statement as LetStatement:
            return evaluateLet(statement: statement, environment: environment)

        default:
            return nil
        }
    }

    func evaluate(expression: Expression, environment: Environment) -> Value {
        switch expression {
        case let expression as IntegerExpression:
            return Integer(value: expression.value)

        case let expression as StringExpression:
            return StringValue(value: expression.token.literal)

        case let expression as BooleanExpression:
            return Boolean(value: expression.value)

        case let expression as PrefixExpression:
            return evaluatePrefix(expression: expression, environment: environment)

        case let expression as InfixExpression:
            return evaluateInfix(expression: expression, environment: environment)

        case let expression as IfExpression:
            return evaluateIf(expression: expression, environment: environment)

        case let expression as IdentifierExpression:
            return evaluateIdentifier(expression: expression, environment: environment)

        case let expression as FunctionExpression:
            return Function(expression: expression, environment: environment)

        case let expression as CallExpression:
            return evaluateCall(expression: expression, environment: environment)

        case let expression as ArrayExpression:
            return evaluateArray(expression: expression, environment: environment)

        case let expression as IndexExpression:
            return evaluateIndex(expression: expression, environment: environment)

        case let expression as HashExpression:
            return evaluateHash(expression: expression, environment: environment)

        default:
            return Null()
        }
    }

    func evaluateBlock(statements: [Statement], environment: Environment) -> Value {
        var result: Value?

        for statement in statements {
            result = evaluate(statement: statement, environment: environment)

            if result is ReturnValue || result is Error {
                break
            }
        }

        return result ?? Null()
    }

    func evaluateReturnValue(statement: ReturnStatement, environment: Environment) -> Value {
        let value = evaluate(expression: statement.returnValue, environment: environment)

        guard !value.isError else {
            return value
        }

        return ReturnValue(value: value)
    }

    func evaluateLet(statement: LetStatement, environment: Environment) -> Value? {
        let value = evaluate(expression: statement.value, environment: environment)

        guard !value.isError else {
            return value
        }

        environment[statement.name.token.literal] = value

        return nil
    }

    func evaluatePrefix(expression: PrefixExpression, environment: Environment) -> Value {
        let right = evaluate(expression: expression.right, environment: environment)

        guard !right.isError else {
            return right
        }

        switch (right, expression.token.kind) {
        case (let node as Integer, .minus):
            return Integer(value: -node.value)

        case (let node as Boolean, .bang):
            return Boolean(value: !node.value)

        case (is Null, .bang):
            return Boolean(value: true)

        case (_, .bang):
            return Boolean(value: false)

        default:
            return Error.unknownPrefixOperator(operator: expression.operator, right: right.type)
        }
    }

    func evaluateInfix(expression: InfixExpression, environment: Environment) -> Value {
        let left = evaluate(expression: expression.left, environment: environment)

        guard !left.isError else {
            return left
        }

        let right = evaluate(expression: expression.right, environment: environment)

        guard !right.isError else {
            return right
        }

        switch (left, right) {
        case (let left as Integer, let right as Integer):
            return evaluateInfixInteger(left: left, right: right, expression: expression, environment: environment)

        case (let left as Boolean, let right as Boolean):
            return evaluateInfixBoolean(left: left, right: right, expression: expression, environment: environment)

        case (let left as StringValue, let right as StringValue):
            return evaluateInfixString(left: left, right: right, expression: expression, environment: environment)

        default:
            return Error.unknownInfixOperator(left: left.type, operator: expression.operator, right: right.type)
        }
    }

    func evaluateInfixInteger(left: Integer, right: Integer, expression: InfixExpression, environment: Environment) -> Value {
        switch expression.token.kind {
        case .plus:
            return Integer(value: left.value + right.value)

        case .minus:
            return Integer(value: left.value - right.value)

        case .asterisk:
            return Integer(value: left.value * right.value)

        case .slash:
            return Integer(value: left.value / right.value)

        case .lt:
            return Boolean(value: left.value < right.value)

        case .gt:
            return Boolean(value: left.value > right.value)

        case .eq:
            return Boolean(value: left.value == right.value)

        case .notEq:
            return Boolean(value: left.value != right.value)

        default:
            return Error.unknownInfixOperator(left: left.type, operator: expression.operator, right: right.type)
        }
    }

    func evaluateInfixString(left: StringValue, right: StringValue, expression: InfixExpression, environment: Environment) -> Value {
        switch expression.token.kind {
        case .plus:
            return StringValue(value: left.value + right.value)

        case .eq:
            return Boolean(value: left.value == right.value)

        case .notEq:
            return Boolean(value: left.value != right.value)

        default:
            return Error.unknownInfixOperator(left: left.type, operator: expression.operator, right: right.type)
        }
    }

    func evaluateInfixBoolean(left: Boolean, right: Boolean, expression: InfixExpression, environment: Environment) -> Value {
        switch expression.token.kind {
        case .eq:
            return Boolean(value: left.value == right.value)

        case .notEq:
            return Boolean(value: left.value != right.value)

        default:
            return Error.unknownInfixOperator(left: left.type, operator: expression.operator, right: right.type)
        }
    }

    func evaluateIf(expression: IfExpression, environment: Environment) -> Value {
        let condition = evaluate(expression: expression.condition, environment: environment)

        guard !condition.isError else {
            return condition
        }

        let isTruthy: Bool

        switch condition {
        case is Null:
            isTruthy = false

        case let condition as Boolean:
            isTruthy = condition.value

        default:
            isTruthy = true
        }

        if isTruthy {
            return evaluate(statement: expression.consequence, environment: environment) ?? Null()
        }
        else if let alternative = expression.alternative {
            return evaluate(statement: alternative, environment: environment) ?? Null()
        }
        else {
            return Null()
        }
    }

    func evaluateIdentifier(expression: IdentifierExpression, environment: Environment) -> Value {
        if let value = environment[expression.token.literal] {
            return value

        }
        else if let builtin = Environment.builtins[expression.token.literal] {
            return builtin
        }
        else {
            return Error.undefinedIdentifier(name: expression.token.literal)
        }
    }

    func evaluateCall(expression: CallExpression, environment: Environment) -> Value {
        let value = evaluate(expression: expression.function, environment: environment)

        guard !value.isError else {
            return value
        }

        switch value {
        case let function as Function:
            let functionEnvironment = Environment(outer: function.environment)

            for (parameter, argument) in zip(function.expression.parameters, expression.arguments) {
                let argument = evaluate(expression: argument, environment: environment)

                if argument.isError {
                    return argument
                }

                functionEnvironment[parameter.token.literal] = argument
            }

            let result = evaluate(statement: function.expression.body, environment: functionEnvironment)

            if let returnValue = result as? ReturnValue {
                return returnValue.value
            }
            else {
                return result ?? Null()
            }

        case let builtin as Builtin:
            var arguments = [Value]()

            for argument in expression.arguments {
                let argument = evaluate(expression: argument, environment: environment)

                if argument.isError {
                    return argument
                }

                arguments.append(argument)
            }

            return builtin.function(arguments)

        default:
            return Error.callNonFunctionValue(type: value.type)
        }
    }

    func evaluateArray(expression: ArrayExpression, environment: Environment) -> Value {
        var elements = [Value]()

        for element in expression.elements {
            let element = evaluate(expression: element, environment: environment)

            if element.isError {
                return element
            }

            elements.append(element)
        }

        return ArrayValue(elements: elements)
    }

    func evaluateIndex(expression: IndexExpression, environment: Environment) -> Value {
        let left = evaluate(expression: expression.left, environment: environment)

        guard !left.isError else {
            return left
        }

        let index = evaluate(expression: expression.index, environment: environment)

        guard !index.isError else {
            return index
        }

        switch (left, index) {
        case (let left as ArrayValue, let index as Integer):
            return evaluateArrayIndex(left: left, index: index)

        case (let left as Hash, let index as AnyHashable):
            return evaluateHashIndex(left: left, index: index)

        case (is Hash, let index):
            return Error.invalidHashKey(type: type(of: index))

        default:
            return Error.indexOperatorNotSupported(type: left.type)
        }
    }

    func evaluateArrayIndex(left: ArrayValue, index: Integer) -> Value {
        if index.value > Int.max || index.value < 0 || index.value >= left.elements.endIndex {
            return Null()
        }

        let index = Int(index.value)
        return left.elements[index]
    }

    func evaluateHash(expression: HashExpression, environment: Environment) -> Value {
        var pairs = [AnyHashable: Value]()

        for (key, value) in expression.pairs {
            let key = evaluate(expression: key, environment: environment)

            guard !key.isError else {
                return key
            }

            guard let hashableKey = key as? AnyHashable else {
                return Error.invalidHashKey(type: type(of: key))
            }

            let value = evaluate(expression: value, environment: environment)

            guard !value.isError else {
                return value
            }

            pairs[hashableKey] = value
        }

        return Hash(pairs: pairs)
    }

    func evaluateHashIndex(left: Hash, index: AnyHashable) -> Value {
        return left.pairs[index] ?? Null()
    }
}

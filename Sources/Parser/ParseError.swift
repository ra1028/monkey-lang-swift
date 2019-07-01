import Token
import AST

public enum ParseError: Error, CustomStringConvertible {
    case invalidTokenFound(expected: TokenKind, got: TokenKind)
    case initialValueNotFound(name: IdentifierExpression)
    case returnValueNotFound
    case prefixOperatorRightValueNotFound(operator: String)
    case infixOperatorRightValueNotFound(operator: String)
    case illegalCharacterFoundInIntegerLiteral(String)
    case illegalCharacterFoundInBooleanLiteral(String)

    public var description: String {
        switch self {
        case .invalidTokenFound(let expected, let got):
            return "Invalid token is found. Expected to be: \(expected), got: \(got)"

        case .initialValueNotFound(let name):
            return "Initial value is not found after '=' for name: \(name)"

        case .returnValueNotFound:
            return "Return value is not found after 'return'"

        case .prefixOperatorRightValueNotFound(let op):
            return "Right value is not found after prefix operator: \(op)"

        case .infixOperatorRightValueNotFound(let op):
            return "Right value is not found after infix operator: \(op)"

        case .illegalCharacterFoundInIntegerLiteral(let literal):
            return "Illegal character found in integer literal: \(literal)"

        case .illegalCharacterFoundInBooleanLiteral(let literal):
            return "Illegal character found in boolean literal: \(literal)"
        }
    }
}

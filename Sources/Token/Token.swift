public struct Token: Hashable {
    public var kind: TokenKind
    public var literal: String

    public init(kind: TokenKind, literal: String) {
        self.kind = kind
        self.literal = literal
    }
}

public extension Token {
    static func lookup(identifier: String) -> Token {
        let kind: TokenKind

        switch identifier {
        case "fn":
            kind = .function

        case "let":
            kind = .let

        case "true":
            kind = .true

        case "false":
            kind = .false

        case "if":
            kind = .if

        case "else":
            kind = .else

        case "return":
            kind = .return

        default:
            return Token(kind: .identifier, literal: identifier)
        }

        return Token(kind: kind, literal: identifier)
    }
}

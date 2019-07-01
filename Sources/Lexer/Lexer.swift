import Token

public struct Lexer {
    public var input: String
    public var position: String.Index
    public var readPosition: String.Index
    public var character: Character?

    public init(input: String) {
        self.input = input
        self.position = input.startIndex
        self.readPosition = input.startIndex >= input.endIndex ? input.endIndex : input.index(after: input.startIndex)
        self.character = input.first
    }

    public mutating func nextToken() -> Token {
        skipWhiteSpace()

        guard let character = character else {
            return Token(kind: .eof, literal: "")
        }

        let kind: TokenKind

        switch character {
        case "=":
            if let peeked = peekChar(), peeked == "=" {
                readChar()
                readChar()
                return Token(kind: .eq, literal: "==")

            }
            else {
                kind = .assign
            }

        case "+":
            kind = .plus

        case "-":
            kind = .minus

        case "!":
            if let peeked = peekChar(), peeked == "=" {
                readChar()
                readChar()
                return Token(kind: .notEq, literal: "!=")
            }
            else {
                kind = .bang
            }

        case "/":
            kind = .slash

        case "*":
            kind = .asterisk

        case "<":
            kind = .lt

        case ">":
            kind = .gt

        case ":":
            kind = .colon

        case ";":
            kind = .semicolon

        case ",":
            kind = .comma

        case "(":
            kind = .lParen

        case ")":
            kind = .rParen

        case "{":
            kind = .lBrace

        case "}":
            kind = .rBrace

        case "[":
            kind = .lBracket

        case "]":
            kind = .rBracket

        case "\"":
            return Token(kind: .string, literal: readString())

        default:
            if character.isIdentifier {
                return .lookup(identifier: readIdentifier())
            }
            else if character.isNumber {
                return Token(kind: .int, literal: readNumber())
            }
            else {
                kind = .illegal
            }
        }

        readChar()

        return Token(kind: kind, literal: String(character))
    }
}

private extension Lexer {
    func peekChar() -> Character? {
        if readPosition >= input.endIndex {
            return nil
        }
        else {
            return input[readPosition]
        }
    }

    mutating func readChar() {
        position = readPosition

        if readPosition >= input.endIndex {
            character = nil
        }
        else {
            character = input[readPosition]
            readPosition = input.index(after: readPosition)
        }
    }

    mutating func readIdentifier() -> String {
        let start = position

        while let character = character, character.isIdentifier {
            readChar()
        }

        return String(input[start..<position])
    }

    mutating func readNumber() -> String {
        let start = position

        while let character = character, character.isNumber {
            readChar()
        }

        return String(input[start..<position])
    }

    mutating func readString() -> String {
        readChar()

        let start = position

        while let character = character {
            defer { readChar() }

            if character == "\"" || character == "\0" {
                return String(input[start..<position])
            }
        }

        return String(input[start..<position])
    }

    mutating func skipWhiteSpace() {
        while let character = character, character.isWhitespace || character.isNewline {
            readChar()
        }
    }
}

private extension Character {
    var isIdentifier: Bool {
        return isLetter || self == "_"
    }
}

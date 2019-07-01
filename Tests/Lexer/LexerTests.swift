import XCTest
import Token
@testable import Lexer

final class LexerTests: XCTestCase {
    func testNextToken() {
        let input = """
        let five = 5;
        let ten = 10;

        let add = fn(x, y) {
          x + y;
        };

        let result = add(five, ten);

        !-/*5;
        5 < 10 > 5;

        if (5 < 10) {
            return true;
        } else {
            return false;
        }

        10 == 10;
        10 != 9;
        "foobar"
        "foo bar"
        [1, 2];
        {"foo": "bar"}
        """

        let expected: [Token] = [
            Token(kind: .let, literal: "let"),
            Token(kind: .identifier, literal: "five"),
            Token(kind: .assign, literal: "="),
            Token(kind: .int, literal: "5"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .let, literal: "let"),
            Token(kind: .identifier, literal: "ten"),
            Token(kind: .assign, literal: "="),
            Token(kind: .int, literal: "10"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .let, literal: "let"),
            Token(kind: .identifier, literal: "add"),
            Token(kind: .assign, literal: "="),
            Token(kind: .function, literal: "fn"),
            Token(kind: .lParen, literal: "("),
            Token(kind: .identifier, literal: "x"),
            Token(kind: .comma, literal: ","),
            Token(kind: .identifier, literal: "y"),
            Token(kind: .rParen, literal: ")"),
            Token(kind: .lBrace, literal: "{"),
            Token(kind: .identifier, literal: "x"),
            Token(kind: .plus, literal: "+"),
            Token(kind: .identifier, literal: "y"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .rBrace, literal: "}"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .let, literal: "let"),
            Token(kind: .identifier, literal: "result"),
            Token(kind: .assign, literal: "="),
            Token(kind: .identifier, literal: "add"),
            Token(kind: .lParen, literal: "("),
            Token(kind: .identifier, literal: "five"),
            Token(kind: .comma, literal: ","),
            Token(kind: .identifier, literal: "ten"),
            Token(kind: .rParen, literal: ")"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .bang, literal: "!"),
            Token(kind: .minus, literal: "-"),
            Token(kind: .slash, literal: "/"),
            Token(kind: .asterisk, literal: "*"),
            Token(kind: .int, literal: "5"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .int, literal: "5"),
            Token(kind: .lt, literal: "<"),
            Token(kind: .int, literal: "10"),
            Token(kind: .gt, literal: ">"),
            Token(kind: .int, literal: "5"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .if, literal: "if"),
            Token(kind: .lParen, literal: "("),
            Token(kind: .int, literal: "5"),
            Token(kind: .lt, literal: "<"),
            Token(kind: .int, literal: "10"),
            Token(kind: .rParen, literal: ")"),
            Token(kind: .lBrace, literal: "{"),
            Token(kind: .return, literal: "return"),
            Token(kind: .true, literal: "true"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .rBrace, literal: "}"),
            Token(kind: .else, literal: "else"),
            Token(kind: .lBrace, literal: "{"),
            Token(kind: .return, literal: "return"),
            Token(kind: .false, literal: "false"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .rBrace, literal: "}"),
            Token(kind: .int, literal: "10"),
            Token(kind: .eq, literal: "=="),
            Token(kind: .int, literal: "10"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .int, literal: "10"),
            Token(kind: .notEq, literal: "!="),
            Token(kind: .int, literal: "9"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .string, literal: "foobar"),
            Token(kind: .string, literal: "foo bar"),
            Token(kind: .lBracket, literal: "["),
            Token(kind: .int, literal: "1"),
            Token(kind: .comma, literal: ","),
            Token(kind: .int, literal: "2"),
            Token(kind: .rBracket, literal: "]"),
            Token(kind: .semicolon, literal: ";"),
            Token(kind: .lBrace, literal: "{"),
            Token(kind: .string, literal: "foo"),
            Token(kind: .colon, literal: ":"),
            Token(kind: .string, literal: "bar"),
            Token(kind: .rBrace, literal: "}"),
            Token(kind: .eof, literal: "")
        ]

        var lexer = Lexer(input: input)

        for expectedToken in expected {
            let token = lexer.nextToken()
            XCTAssertEqual(token, expectedToken)
        }
    }
}

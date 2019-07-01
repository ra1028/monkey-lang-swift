public enum TokenKind: Hashable {
    /// Unknown token
    case illegal

    /// End of file
    case eof

    /// add, foobar, x, y
    case identifier

    /// 1234567890
    case int

    /// "foobar"
    case string

    /// =
    case assign

    /// +
    case plus

    /// -
    case minus

    /// !
    case bang

    /// *
    case asterisk

    /// /
    case slash

    /// <
    case lt

    /// >
    case gt

    /// ,
    case comma

    /// ;
    case colon

    /// ;
    case semicolon

    /// (
    case lParen

    /// )
    case rParen

    /// {
    case lBrace

    /// }
    case rBrace

    /// [
    case lBracket

    /// ]
    case rBracket

    /// fn
    case function

    /// let
    case `let`

    /// true
    case `true`

    /// false
    case `false`

    /// if
    case `if`

    /// else
    case `else`

    /// return
    case `return`

    /// ==
    case eq

    /// !=
    case notEq
}

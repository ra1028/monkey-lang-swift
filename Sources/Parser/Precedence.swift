enum Precedence: Int, Comparable {
    case lowest
    case equals
    case lessGreater
    case sum
    case product
    case prefix
    case call
    case index

    static func < (lhs: Precedence, rhs: Precedence) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

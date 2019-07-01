public protocol Node: CustomStringConvertible {}

public struct Program: Node {
    public var statements: [Statement]

    public var description: String {
        return statements.lazy
            .map { $0.description }
            .joined()
    }

    public init(statements: [Statement]) {
        self.statements = statements
    }
}

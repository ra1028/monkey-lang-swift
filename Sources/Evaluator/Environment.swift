import AST

public final class Environment {
    private let outer: Environment?
    private var map = [String: Value]()

    public subscript(name: String) -> Value? {
        get {
            return map[name] ?? outer?[name]
        }
        set {
            map[name] = newValue
        }
    }

    public init(map: [String: Value] = [:]) {
        outer = nil
        self.map = map
    }

    public init(outer: Environment) {
        self.outer = outer
        map = [:]
    }
}

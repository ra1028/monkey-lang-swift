public struct CLI {
    public init() {}

    public func run() {
        let arguments = CommandLine.arguments.dropFirst()
        let command = self.command(for: arguments)
        command.run()
    }
}

private extension CLI {
    func command<C: Collection>(for arguments: C) -> Command where C.Element == String {
        switch arguments.first {
        case "repl"?, .none:
            return REPLCommand()

        case let argument?:
            return RunCommand(filePath: argument)
        }
    }
}

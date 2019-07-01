import Parser
import Evaluator

struct REPLCommand: Command {
    private var exitCommand = "exit"
    private var environment = Environment()

    func run() {
        while true {
            print("monkey>", terminator: " ")

            guard let input = readLine(strippingNewline: true) else {
                continue
            }

            guard input != exitCommand else {
                break
            }

            var parser = Parser(input: input)
            let program = parser.parse()
            let evaluator = Evaluator(program: program)

            if !parser.errors.isEmpty {
                print("Parse failed with error(s):")

                for error in parser.errors {
                    print("    \(error)")
                }

                continue
            }
            else if let result = evaluator.evaluate(environment: environment) {
                print(result)
            }
        }
    }
}

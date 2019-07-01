import Foundation
import Parser
import Evaluator

struct RunCommand: Command {
    var filePath: String

    func run() {
        do {
            let input = try String(contentsOfFile: filePath)
            var parser = Parser(input: input)
            let program = parser.parse()
            let evaluator = Evaluator(program: program)
            let environment = Environment()

            if !parser.errors.isEmpty {
                print("Parse failed with error(s):")

                for error in parser.errors {
                    print(error)
                }

                return
            }
            else if let result = evaluator.evaluate(environment: environment) {
                print(result)
            }
        }
        catch {
            print("monkey> No such file or directory -- \(filePath)\n\n\(error)")
        }
    }
}

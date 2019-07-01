import XCTest

import EvaluatorTests
import LexerTests
import ParserTests

var tests = [XCTestCaseEntry]()
tests += EvaluatorTests.__allTests()
tests += LexerTests.__allTests()
tests += ParserTests.__allTests()

XCTMain(tests)

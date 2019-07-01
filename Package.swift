// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "monkey",
    products: [
        .executable(name: "monkey", targets: ["Monkey"])
    ],
    targets: [
        .target(
            name: "Monkey",
            dependencies: [
                "CLI",
            ],
            path: "Sources/Monkey"
        ),
        .target(
            name: "CLI",
            dependencies: [
                "Parser",
                "Evaluator"
            ],
            path: "Sources/CLI"
        ),
        .target(
            name: "Token",
            path: "Sources/Token"
        ),
        .target(
            name: "Lexer",
            dependencies: ["Token"],
            path: "Sources/Lexer"
        ),
        .target(
            name: "AST",
            dependencies: ["Token"],
            path: "Sources/AST"
        ),
        .target(
            name: "Parser",
            dependencies: [
                "Lexer",
                "AST"
            ],
            path: "Sources/Parser"
        ),
        .target(
            name: "Evaluator",
            dependencies: ["AST"],
            path: "Sources/Evaluator"
        ),
        .testTarget(
            name: "LexerTests",
            dependencies: ["Lexer"],
            path: "Tests/Lexer"
        ),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"],
            path: "Tests/Parser"
        ),
        .testTarget(
            name: "EvaluatorTests",
            dependencies: [
                "Evaluator",
                "Parser"
            ],
            path: "Tests/Evaluator"
        )
    ]
)

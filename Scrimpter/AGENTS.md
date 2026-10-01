# Scrimpter Agent Overview

## Project Description

The `Scrimpter` project is a custom scripting language that was intended to be used for creating formula elements in the _MAD Designer_ application. It includes a parser, a scanner, and a set of classes for representing the abstract syntax tree (AST) of a script.

**Note:** According to the main project `AGENTS.md` file, this project is **not currently used** in the main application. However, it is still maintained.

## Key Features

*   **Custom Scripting Language**: The project defines a custom scripting language that can be used to perform calculations and manipulate data.
*   **Parser and Scanner**: It includes a parser (`parser.ym`) and a scanner (`scanner.lm`) that are used to read a script and convert it into an AST.
*   **Abstract Syntax Tree (AST)**: The framework provides a set of classes for representing the AST of a script. This allows the script to be analyzed, optimized, and executed.
*   **Symbol Table**: It includes a symbol table for managing the variables and functions that are defined in a script.

## Core Components

*   **`parser.ym`**: The grammar for the Scrimpter language, written in a format that is compatible with the `yacc` parser generator.
*   **`scanner.lm`**: The lexical analyzer for the Scrimpter language, written in a format that is compatible with the `lex` scanner generator.
*   **`MTAbstractSyntaxTree`**: The main class for representing the AST of a script.
*   **`MTAstNode...`**: A set of classes that represent the different types of nodes in the AST (e.g., arithmetic operations, function calls, statements).
*   **`MADSymbolTable`**: A class for managing the symbols (variables and functions) that are used in a script.
*   **`MADScrimpter`**: The main class for interacting with the Scrimpter engine. It likely provides methods for parsing and executing scripts.

## Usage Guidelines

As this project is **not currently used** in the main application, it is not recommended to use it in new code without first consulting with the project owner.

If you are tasked with maintaining or extending the Scrimpter language, you will need to familiarize yourself with the `parser.ym` and `scanner.lm` files, as well as the various `MTAstNode...` classes. Any changes to the language's syntax will require modifications to the parser and scanner files, followed by a regeneration of the parser and scanner code.

## Testing and Reports

*   **Tests**: `Scrimpter/ScrimpterTests`. Run with
    `xcodebuild test -workspace Reports.xcworkspace -scheme None -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
*   **Tracking**: [`BUGS.md`](../BUGS.md) -- the defect register; [`TASKS.md`](../TASKS.md) -- the engineering queue. Maintain them, but do not start work from them.
*   **Note**: the test target is in the Xcode project but no shared scheme runs it.

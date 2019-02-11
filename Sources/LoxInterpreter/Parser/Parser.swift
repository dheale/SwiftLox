//
//  Parser.swift
//  LoxFramework
//
//  Created by Dominic Heale on 05/02/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation


// LOX EXPRESSION GRAMMAR:
// expression → literal
//    | unary
//    | binary
//    | grouping ;
//
// literal    → NUMBER | STRING | "false" | "true" | "nil" ;
// grouping   → "(" expression ")" ;
// unary      → ( "-" | "!" ) expression ;
// binary     → expression operator expression ;
// operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
//     | "+"  | "-"  | "*" | "/" ;

// REWRITTEN AS ONE RULE PER PRECEDENCE ORDER (see binary is expanded out)
// expression     → equality ;
// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
// comparison     → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;
// addition       → multiplication ( ( "-" | "+" ) multiplication )* ;
// multiplication → unary ( ( "/" | "*" ) unary )* ;
// unary          → ( "!" | "-" ) unary
// | primary ;
// primary        → NUMBER | STRING | "false" | "true" | "nil"
// | "(" expression ")" ;
 class Parser {
    enum Error: Swift.Error {
        static let returnCode: Int32 = 65

        case unexpectedToken(found: Token, message: String)
        
        /// We got to the end of the input and we were expecting an expression
        case expressionExpected(message: String)
        
        case unexpectedlyAtEof
        
        var message: String {
            switch self {
            case let .unexpectedToken(found: _, message: message):
                return message
            case let .expressionExpected(message: message):
                return message
            case .unexpectedlyAtEof:
                return "Unexpectedly at EOF"
            }
        }
    }
    
    var interpreter: LoxInterpreter
    var tokens: [Token]
    var current = 0 // Index into tokens
    
    init(tokens: [Token], interpreter: LoxInterpreter) {
        self.tokens = tokens
        self.interpreter = interpreter
    }
    
    private var isAtEnd: Bool {
        return peek()?.type == .eof || current >= tokens.count
    }
    
    private func peek() -> Token? {
        guard current < tokens.count else {
            return nil
        }
        return tokens[current]
    }
    
    private var previous: Token { return tokens[current - 1] }
    
    @discardableResult
    private func advance() -> Token {
        if isAtEnd == false { current += 1 }
        return previous
    }
    
    private func check(_ type: Token.TType) -> Bool {
        guard let p = peek() else { return false }
        return p.isType(type)
    }
    
    // checks to see if the current token is any of the given types
    // If so, it consumes it and returns true. Otherwise, it returns false
    // and leaves the token where it is
    private func match(_ tokens: Token.TType...) -> Bool {
        for token in tokens {
            if check(token) {
                advance()
                return true
            }
        }
        
        return false
    }
    
    private func comparison() throws -> Expression {
        var expr = try addition()
        
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let op = previous
            let right = try addition()
            expr = .binary(expr, op, right)
        }
        
        return expr
    }
    
    private func addition() throws -> Expression {
        var expr = try multiplication()
        
        while match(.minus, .plus) {
            let op = previous
            let right = try multiplication()
            expr = .binary(expr, op, right)
        }
        
        return expr
    }
    
    private func multiplication() throws -> Expression {
        var expr = try unary()
        
        while match(.slash, .star) {
            expr = try .binary(expr, previous, unary())
        }
        
        return expr
    }
    
    private func unary() throws -> Expression {
        if match(.bang, .minus) {
            return try .unary(previous, unary())
        }
        
        return try call()
    }

    private func call() throws -> Expression {
        var expr = try primary()
        
        while (true) {
            if match(.leftParen) {
                expr = try finishCall(expr)
            }
            else if match(.dot) {
                let name = try consume(.identifier(""), message: "Expect property name after '.'.")
                // No you can't return directly here
                expr = .get(object: expr, name: name)
            }
            else {
                break
            }
        }
        
        return expr
    }
    
    private func finishCall(_ callee: Expression) throws -> Expression {
        var arguments: [Expression] = []
        
        if (!check(.rightParen)) {
            repeat {
                if arguments.count >= Lox.Constants.maxNumberOfFunctionArguments {
                    interpreter.error(peek()!, "Cannot have more than \(Lox.Constants.maxNumberOfFunctionArguments) arguments.")
                }
                arguments.append(try expression())
            } while match(.comma)
        }
        
        let paren = try consume(.rightParen, message: "Expect ')' after arguments.")
        
        return .call(callee: callee, paren: paren, arguments: arguments)
    }
    
    @discardableResult
    private func consume(_ type: Token.TType, message: String) throws -> Token {
        if check(type) { return advance() }
        
        if let gotInstead = peek() {
            throw Error.unexpectedToken(found: gotInstead, message: message)
        }
        
        throw Error.unexpectedlyAtEof
    }
    
    private func declaration() -> Statement? {
        do {
            if match(.class) { return try classDeclaration() }
            if match(.fun) { return try funDeclarationOrLambdaCallStatement() }
            if match(.var) { return try varDeclaration() }
            return try statement()
        } catch {
            interpreter.hadError = true
            func errorAt() -> String {
                guard let place = peek()?.lexeme, place.count > 0 else { return "Error at end" }
                return "Error at '\(place)'"
            }
            
            if case let Error.expressionExpected(message: message) = error {
                fputs("[line \(lineNumber)] \(errorAt()): \(message)\n", stderr)
                synchronize()
                return nil
            }
            else if case let Error.unexpectedToken(found: _, message: message) = error {
                
                fputs("[line \(lineNumber)] \(errorAt()): \(message)\n", stderr)
                synchronize()
                return nil
            }
            return nil
        }
    }
    
    private func classDeclaration() throws -> Statement {
        let name = try consume(.identifier(""), message: "Expect class name when defining a class.")

        let superclass: Expression? = try {
            guard match(.less) else { return nil }
            try consume(.identifier(""), message: "Expect superclass name.")
            return .variable(name: previous)
        }()
        
        try consume(.leftBrace, message: "Expect '{' before class body.")
        
        // A list of function definition statements
        var methods: [Statement] = []

        while !(check(.rightBrace) || isAtEnd) {
            try methods.append(function())
            // methods.add(function("method"));
        }
        
        try consume(.rightBrace, message: "Expect '}' after class body.")
        
        return .class(name: name,
                      superclass: superclass,
                      methods: methods)
    }
    
    private func function() throws -> Statement {
        let name = try consume(.identifier(""), message: "Expect function name.")
        let definition = try funDefinition()
        guard case let .lambda(def) = definition else { fatalError() }
        
        return .function(name: name, definition: def)
    }
    
    private func funDeclarationOrLambdaCallStatement() throws -> Statement {
        if check(.identifier("")) {
            return try function()
        } else {
            let definition = try funDefinition()
            guard case .lambda = definition else { throw Error.expressionExpected(message: "Expecting lambda immediate call") }
            // if we have a lambda at declaration scope, then unless it's called
            try consume(.leftParen, message: "Expect '(' after function.")
            let expr = try finishCall(definition)
            try consume(.semicolon, message: "Missing semicolon after anonymous function call")
            return Statement.expression(expr)
        }
    }
    
    private func funDefinition() throws -> Expression {
        try consume(.leftParen, message: "Expect '(' after function name.")
        var params = Array<Token>()
        if !check(.rightParen) {
            repeat {
                if params.count >= Lox.Constants.maxNumberOfFunctionArguments {
                    interpreter.error(peek()!, "Cannot have more than \(Lox.Constants.maxNumberOfFunctionArguments) parameters.")
                }
                
                params.append(try consume(.identifier(""), message: "Expect parameter name."))
            } while match(.comma)
        }
        
        try consume(.rightParen, message: "Expect ')' after parameters.") // in function.")
        
        // the body of the function
        try consume(.leftBrace, message: "Expect '{' before function body.")
        let body = try block()
        return Expression.lambda(FunctionDefinition(parameters: params, body: body))
    }
    
    // We have just matched 'var' so look for ('name', =, 'expr')
    private func varDeclaration() throws -> Statement {
        let nameToken = try consume(.identifier(""), message: "Expect variable name.")
        
        let initializer: Expression? = try {
            if match(Token.TType.equal) { return try expression() }
            return nil
        }()
        
        try consume(.semicolon, message: "Expect ';' after variable declaration.")
        return Statement.variable(name: nameToken, initializer: initializer)
    }

    private func statement() throws -> Statement {
        if match(.for) { return try forStatement() }
        if match(.if) { return try ifStatement() }
        if match(.print) { return try printStatement() }
        if match(.return) { return try returnStatement() }
        if match(.while) { return try whileStatement() }
        if match(.leftBrace) { return try .block(block()) }
        return try expressionStatement()
    }
    
    private func returnStatement() throws -> Statement {
        let keyword = previous
        let value: Expression = try {
            if check(.semicolon) {
                return .literal(.nil)
            }
            return try expression()
        }()
        
        try consume(.semicolon, message: "Expect ';' after return value.")

        return .return(token: keyword, expression: value)
    }
    
    private func forStatement() throws -> Statement {
        try consume(.leftParen, message: "Expect '(' after 'for'")
        let initializer: Statement? = try {
            if match(.semicolon) { return nil }
            else if match(.var) {
                return try varDeclaration()
            } else {
                return try expressionStatement()
            }
        }()
        
        var condition: Expression? = nil
        if !check(.semicolon) {
            condition = try expression()
        }
        try consume(.semicolon, message: "Expect ';' after loop condition.")
        
        var increment: Expression? = nil
        if !check(.rightParen)  {
            increment = try expression()
        }
        try consume(.rightParen, message: "Expect ')' after for statement.")
        
        var body = try statement()
        
        if let inc = increment {
            body = Statement.block([
                body,
                .expression(inc) ])
        }
        
        if condition == nil { condition = .literal(.bool(true)) }
        body = Statement.while(condition: condition!, body: body)
        
        if let initial = initializer {
            body = Statement.block([initial, body])
        }
        
        return body
    }
    
    private func whileStatement() throws -> Statement {
        try consume(.leftParen, message: "Expect '(' after 'while'")
        let condition = try expression()
        try consume(.rightParen, message: "Expect ')' after 'while' condition")
        let body = try statement()
        
        return .while(condition: condition, body: body)
    }
    
    private func ifStatement() throws -> Statement {
        try consume(.leftParen, message: "Expect '(' after 'if'.")
        let condition = try expression()
        try consume(.rightParen, message: "Expect ')' after 'if'.")
        let thenBranch = try statement()
        let elseBranch: Statement? = try {
            guard (match(.else)) else { return nil }
            return try statement()
        }()
        
        return .if(condition, then: thenBranch, else: elseBranch)
    }
    
    private func block() throws -> [Statement] {
        var statements: [Statement] = []
        
        while (!(check(.rightBrace) || isAtEnd)) {
            if let dec = declaration() {
                statements.append(dec)
            }
        }
        
        try consume(.rightBrace, message: "Expect '}' after block.")
        return statements
    }
    
    private func printStatement() throws -> Statement  {
        let value = try expression()
        try consume(.semicolon, message: "Expect ';' after value.")
        return .print(value)
    }
    
    private func expressionStatement() throws -> Statement {
        let expr = try expression()
        try consume(.semicolon, message: "Expect ';' after expression.")
        return .expression(expr)
    }
    
    private func expression() throws -> Expression {
        return try assignment()
    }
    
    private func `or`() throws -> Expression {
        var expr = try `and`()
        
        while match(.or) {
            let `operator` = previous
            let right = try `and`()
            expr = .logical(left: expr, operator: `operator`, right: right)
        }
        
        return expr
    }
    
    private func `and`() throws -> Expression {
        var expr = try equality()
        
        while match(.and) {
            let `operator` = previous
            let right = try equality()
            expr = .logical(left: expr, operator: `operator`, right: right)
        }
        
        return expr

    }
    
    private func assignment() throws -> Expression {
        let expr = try `or`()
        
        if match(.equal) {
            // the equals token
            let equals = previous
            let value = try assignment()
            
            // assign to the var on the lhs
            if case let .variable(token) = expr {
                return .assign(name: token, value: value)
            } else if case let .get(object, name) = expr {
                // if we have a . combined with an = then we are
                // assigning to the property on the instance, not getting
                return .set(object: object, name: name, value: value)
            }
            
            // report an error but don't throw it because
            // we don't want to 'synchronize' and start looking for
            // valid code again
            interpreter.error(equals, "Invalid assignment target.")
        }
        
        return expr
    }
    
    // --------------------------------------------------
    
    var lineNumber: Int {
        if current > 0 {
            return previous.lineNumber
        } else {
            return tokens.first?.lineNumber ?? 1
        }
    }
    
    func parse() throws -> [Statement] {
        var statements: [Statement] = []

        while !isAtEnd {
            if let dec = declaration() {
                statements.append(dec)
            }
        }
        
        return statements
    }
    
    private func synchronize() {
        advance()
        while !isAtEnd {
            if previous.type == .semicolon { return }
            switch peek()!.type {
            case .print, .var, .class, .fun, .for, .if, .while, .return: return
            default: advance()
            }
        }

    }

    private  // equality → comparison ( ( "!=" | "==" ) comparison )* ;
    func equality() throws -> Expression {
        var expr = try comparison()
        
        while (match(.bangEqual, .equalEqual)) {
            let op = previous
            let right = try comparison()
            expr = .binary(expr, op, right)
        }
        
        return expr
    }
    
    
    func primary() throws -> Expression {
        func matchNumberOrString() -> Expression? {
            guard let p = peek() else { return nil }
            
            switch p.type {
            case .number(let num):
                advance()
                return .literal(.number(num))
            case .string(let str):
                advance()
                return .literal(.string(str))
            default:
                return nil
            }
        }
        
        if match(.false) { return .literal(.bool(false)) }
        if match(.true)  { return .literal(.bool(true))  }
        if match(.nil)   { return .literal(.nil)   }
        
        if let expr = matchNumberOrString() { return expr }
        
        if match(.leftParen) {
            let expr = try expression()
            try consume(Token.TType.rightParen.self, message: "Expect ')' after expression.")
            return .grouping(expr)
        }
        
        if match(.super) {
            let keyword = previous
            try consume(.dot, message: "Expect '.' after 'super'.")
            let method = try consume(.identifier(""), message:
                                   "Expect superclass method name.")
            return .super(keyword: keyword, method: method)
        }
        
        if match(.this) {
            return .this(name: previous)
        }
        
        if match(.identifier("")) {
            return .variable(name: previous)
        }
            
        throw(Error.expressionExpected(message:
            "[line \(lineNumber)] Error at \'\(peek()?.lexeme ?? "EOF")\': Expect expression.\n"))
    }
}

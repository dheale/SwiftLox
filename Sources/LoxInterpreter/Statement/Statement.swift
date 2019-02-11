//
//  Statement.swift
//  LoxFramework
//
//  Created by Dominic Heale on 08/11/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

struct FunctionDefinition {
    let parameters: [Token]
    let body: [Statement]
}

struct ResolvedFunctionDefinition {
    let parameters: [Token]
    let body: [ResolvedStatement]
}

indirect enum Statement {
    case expression(Expression)
    case print(Expression)
    case block([Statement])
    case `if`(Expression, then: Statement, else: Statement?)

    // A variable declaration, name = variable
    case variable(name: Token, initializer: Expression?)
    
    case `while`(condition: Expression, body: Statement)
    
    // function definition
    case function(name: Token, definition: FunctionDefinition)
    
    case `return`(token: Token, expression: Expression)
    
    case `class`(name: Token, superclass: Expression?, methods: [Statement])
}

extension ResolvedStatement {
    func execute(_ environment: Environment) throws {
        switch self {
        case let .expression(e):
            _ = try e.evaluated(environment)
        case let .print(e):
            let v = try e.evaluated(environment)
            Swift.print(v)
            
        // a new variable declaration
        case let .variable(name: name, initializer: initializer):
            let value: Literal = try {
                guard let ini = initializer else { return .`nil` }
                return try ini.evaluated(environment)
            }()
            
            environment.define(name: name.lexeme, value: value)
            
        case let .block(statements):
            let blockEnv = Environment(parent: environment)
            for statement in statements {
                try statement.execute(blockEnv)
            }
        
        case let .if(expression, `then`, `else`):
            if try expression.evaluated(environment).isTruthy {
                try `then`.execute(environment)
            } else if let elseBranch = `else` {
                try elseBranch.execute(environment)
            }
        
        case let .`while`(condition, statement):
            while try condition.evaluated(environment).isTruthy {
                try statement.execute(environment)
            }
            
        case let .function(name: name, definition: definition):
            let f = UserFunction(definition: definition,
                                 env: environment,
                                 isInitializer: false,
                                 description: "<fn \(name.lexeme)>")
            environment.define(name: name.lexeme, value: .function(f))
            
        case let .return(_, expression):
            throw try ReturnValue(value: expression.evaluated(environment))
            
        case let .class(token, possibleSuperclassExpr, statementmethods):
            
            let (sup, environ): (Class?, Environment) = try {
                guard let superclassExpr = possibleSuperclassExpr else { return (nil, environment) }
                let result = try superclassExpr.evaluated(environment)
                
                guard case let .class(c) = result
                    else { throw RuntimeError(token: token, message: "Superclass must be a class.") }
                
                let superEnv = Environment(parent: environment)
                superEnv.define(name: "super", value: result)
                return (c, superEnv)
            }()

            environment.define(name: token.lexeme, value: .nil)
            
            var res = [String : Function]()
            for t in statementmethods {
                guard case let .function(name, definition) = t else { continue }
                let n = name.lexeme

                res[n] = UserFunction(definition: definition,
                                                env: environ,
                                                isInitializer: n == "init",
                                                description: n)
            }
            
            let c = Class(name: token.lexeme,
                          superclass: sup,
                          methods: res)
            try environment.assign(name: token, value: Literal.class(c), depth: 0)
            break
        }
    }
}

// For a return statement, we want to unwind the call stack to the caller of the function
// We do that by throwing an expection which we catch, containing the return value
struct ReturnValue: Error {
    let value: Literal
}

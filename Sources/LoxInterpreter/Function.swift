//
//  Function.swift
//  LoxInterpreter
//
//  Created by Dominic Heale on 22/11/2018.
//

import Foundation

protocol Function: Callable { }

struct BuiltIn: Function {
    let arity: Int
    let body: ([Literal]) throws -> Literal
    
    func call(_ arguments: [Literal]) throws -> Literal {
        return try body(arguments)
    }
    
    var description: String {
        return "<native fn>"
    }
}

//// Is not a function because it's not callable

class UserFunction: Function {
    init(definition: ResolvedFunctionDefinition,
         env: Environment,
         isInitializer: Bool,
         description: String) {
        self.definition = definition
        self.env = env
        self.isInitializer = isInitializer
        self.description = description
    }
    
    let definition: ResolvedFunctionDefinition
    let env: Environment
    
    // If this function is the init method of a class
    let isInitializer: Bool
    
    var arity: Int {
        return definition.parameters.count
    }
    
    var description: String
    
    func call(_ arguments: [Literal]) throws -> Literal {
        let functionCallEnvironment = Environment(parent: env)

        for (param, argument) in zip(definition.parameters, arguments) {
            functionCallEnvironment.define(name: param.lexeme, value: argument)
        }
        
        for statement in definition.body {
            do {
                try statement.execute(functionCallEnvironment)
            }
            catch let r as ReturnValue {
                if isInitializer {
                    return try env.getThis()
                } else {
                    throw r
                }
            }
        }
        
        if isInitializer {
            return try env.getThis()
        }
        
        return .nil
    }
}

//  This needs to be an extension on methods only
extension UserFunction {
    func bind(_ instance: Instance) -> Function {
        let environment = Environment(parent: env)
        environment.define(name: "this", value: .instance(instance))
        
        return UserFunction(definition: definition,
                            env: environment,
                            isInitializer: isInitializer,
                            description: "<fn method>") as Function
    }
}

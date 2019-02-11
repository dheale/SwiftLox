//
//  Environment.swift
//  LoxFramework
//
//  Created by Dominic Heale on 09/11/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

class Environment {
    let parent: Environment?
    
    init(parent: Environment?) {
        self.parent = parent
    }
    
    var values: [String : Literal] = [:]
    
    func define(name: String, value: Literal) {
        values[name] = value
    }
    
    func defining(name: String, value: Literal) -> Environment {
        define(name: name, value: value)
        return self
    }
    
    // A block statement introduces a new scope for the statements it contains.
    // A function declaration introduces a new scope for its body and
    //    binds its parameters in that scope.
    // A variable declaration adds a new variable to the current scope.
    // Variable and assignment expressions need to have their variables resolved.
    
    func get(name: Token, depth: Int) throws -> Literal {
        guard depth >= 0 else { fatalError() }
        
        guard depth == 0 else {
            guard let p = parent else {
                throw RuntimeError(token: name,
                                    message: "Undefined variable '\(name.lexeme)'.")
            }

            return try p.get(name: name, depth: depth - 1)
        }
        
        if let literal = values[name.lexeme] {
            return literal
        }
        
        throw RuntimeError(token: name,
                           message: "Undefined variable '\(name.lexeme)'.")
    }
    
    func get(name: String, depth: Int) throws -> Literal {
        guard depth >= 0 else { fatalError() }
        
        guard depth == 0 else {
            guard let p = parent else {
                throw RuntimeError(token: nil,
                                   message: "Undefined variable '\(name)'.")
            }
            
            return try p.get(name: name, depth: depth - 1)
        }
        
        if let literal = values[name] {
            return literal
        }
        
        throw RuntimeError(token: nil,
                           message: "Undefined variable '\(name)'.")
    }
    
    // Only call when in a method
    func getThis() throws -> Literal {
        guard let literal = values["this"] else {
            fatalError("Intepreter error: can't find this")
        }
        
        return literal
    }
    
    func assign(name: Token, value: Literal, depth: Int) throws {
        guard depth >= 0 else { fatalError() }

        guard depth == 0 else {
            guard let p = parent else {
                throw RuntimeError.init(token: name,
                                        message: "Undefined variable over global scope: '\(name.lexeme)'.")
            }

            try p.assign(name: name, value: value, depth: depth - 1)
            return
        }
        
        if values[name.lexeme] != nil {
            values[name.lexeme] = value
        } else {
            throw RuntimeError.init(token: name,
                                    message: "Undefined variable '\(name.lexeme)'.")
        }
    }
}

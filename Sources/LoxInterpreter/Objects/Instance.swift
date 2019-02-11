//
//  Instance.swift
//  CommandLineKit
//
//  Created by Dominic Heale on 27/12/2018.
//

import Foundation

// An instance of a user-defined Lox class
class Instance {
    var fields = [String: Literal]()
    
    let `class`: Class
    
    init(_ c: Class) {
        `class` = c
    }
    
    func get(_ name: Token) throws -> Literal {
        // Look up a field first => fields shadow methods
        if let value = fields[name.lexeme] {
            return value
        }
        
        if let method = `class`.find(instance: self, method: name.lexeme) {
            return .function(method)
        }
        
        throw RuntimeError(token: name,
                           message: "Undefined property '\(name.lexeme)'.")
    }
    
    func set(_ name: Token, _ value: Literal) {
        fields[name.lexeme] = value
    }
}

extension Instance: CustomStringConvertible {
    var description: String {
        return "\(`class`.name) instance"
    }
}

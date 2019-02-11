//
//  Token.swift
//  Lox
//
//  Created by Dominic Heale on 19/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

struct Token {
    
    enum TType {
        // Single-character tokens.
        case leftParen
        case rightParen
        case leftBrace
        case rightBrace
        case comma
        case dot
        case minus
        case plus
        case semicolon
        case slash
        case star
        
        // One or two character tokens.
        case bang
        case bangEqual
        
        case equal
        case equalEqual
        case greater
        case greaterEqual
        case less
        case lessEqual
        
        // Literals.
        case identifier(String)
        case string(String)
        case number(Double) // only a double?
        
        // Keywords.
        case and
        case `class`
        case `else`
        case `false`
        case fun
        case `for`
        case `if`
        case `nil`
        case `or`
        case `print`
        case `return`
        case `super`
        case `this`
        case `true`
        case `var`
        case `while`
        
        case eof
        
        init?(character: Character) {
            switch (character) {
            case "(": self = .leftParen
            case ")": self = .rightParen
                
            case "{": self = .leftBrace
            case "}": self = .rightBrace
            case ",": self = .comma
            case ".": self = .dot
            case "-": self = .minus
            case "+": self = .plus
            case ";": self = .semicolon
            case "*": self = .star
            default:
                return nil
            }
        }
        
        /// String protocol here lets us use either a string or a substring
        init?<S: StringProtocol>(identifierOrReservedWord s: S) {
            switch s {
            case "and": self = .and
            case "class": self = .class
            case "else": self = .else
            case "false": self = .false
            case "for": self = .for
            case "fun": self = .fun
            case "if": self = .if
            case "nil": self = .nil
            case "or": self = .or
            case "print": self = .`print`
            case "return": self = .return
            case "super": self = .super
            case "this": self = .this
            case "true": self = .true
            case "var": self = .var
            case "while": self = .while
            default: self = .identifier(String(s))
            }
        }
    }

    let type: TType
    let lineNumber: Int
    
    let lexeme: String
}


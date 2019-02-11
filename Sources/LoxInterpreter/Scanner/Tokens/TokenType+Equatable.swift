//
//  TokenType+Equatable.swift
//  LoxMain
//
//  Created by Dominic Heale on 23/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension Token {
    func isType(_ type: Token.TType) -> Bool {
        return self.type == type
    }
    
    /// Returns true if the token is the same enum case, ignoring any
    /// associated values, like two strings could be different
    /// but they're both strings, same with numbers. Most tokens don't
    /// have associated values so are the same, e.g. two open brackets.
    func isSameKindAs(_ other: Token) -> Bool {
        return self.type == other.type
    }
}

extension Token.TType: Equatable
{
    public static func ==(lhs: Token.TType, rhs: Token.TType) -> Bool
    {
        switch (lhs, rhs) {
        // Single-character tokens.
        case (leftParen, leftParen),
         (rightParen, rightParen),
         (leftBrace, leftBrace),
         (rightBrace, rightBrace),
         (comma, comma),
         (dot, dot),
         (minus, minus),
         (plus, plus),
         (semicolon, semicolon),
         (slash, slash),
         (star, star),
            
        // One or two character tokens.
         (bang, bang),
         (bangEqual, bangEqual),
            
         (equal, equal),
         (equalEqual, equalEqual),
         (greater, greater),
         (greaterEqual, greaterEqual),
         (less, less),
         (lessEqual, lessEqual),
            
        // Literals.
         (identifier(_), identifier(_)),
         (string(_), string(_)),
         (number(_), number(_)), // only a double?
            
        // Keywords.
         (and, and),
         (`class`, `class`),
         (`else`, `else`),
         (`false`, `false`),
         (fun, fun),
         (`for`, `for`),
         (`if`, `if`),
         (`nil`, `nil`),
         (`or`, `or`),
         (`print`, `print`),
         (`return`, `return`),
         (`super`, `super`),
         (`this`, `this`),
         (`true`, `true`),
         (`var`, `var`),
         (`while`, `while`),
         (eof, eof): return true
            
        case (leftParen, _),
             (rightParen, _),
             (leftBrace, _),
             (rightBrace, _),
             (comma, _),
             (dot, _),
             (minus, _),
             (plus, _),
             (semicolon, _),
             (slash, _),
             (star, _),
             
             // One or two character tokens.
        (bang, _),
        (bangEqual, _),
        
        (equal, _),
        (equalEqual, _),
        (greater, _),
        (greaterEqual, _),
        (less, _),
        (lessEqual, _),
        
        // Literals.
        (identifier(_), _),
        (string(_), _),
        (number(_), _), // only a double?
        
        // Keywords.
        (and, _),
        (`class`, _),
        (`else`, _),
        (`false`, _),
        (fun, _),
        (`for`, _),
        (`if`, _),
        (`nil`, _),
        (`or`, _),
        (`print`, _),
        (`return`, _),
        (`super`, _),
        (`this`, _),
        (`true`, _),
        (`var`, _),
        (`while`, _),
        (eof, _):
            return false
        }
    }
}

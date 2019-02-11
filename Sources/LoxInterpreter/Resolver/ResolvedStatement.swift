//
//  ResolvedStatement.swift
//  CommandLineKit
//
//  Created by Dominic Heale on 04/01/2019.
//

import Foundation

indirect enum ResolvedStatement: CustomStringConvertible {
    case expression(ResolvedExpression)
    case print(ResolvedExpression)
    case block([ResolvedStatement])
    case `if`(ResolvedExpression, then: ResolvedStatement, else: ResolvedStatement?)
    case variable(name: Token, initializer: ResolvedExpression?)
    case `while`(condition: ResolvedExpression, body: ResolvedStatement)
    case function(name: Token, definition: ResolvedFunctionDefinition)
    case `return`(token: Token, expression: ResolvedExpression)
    case `class`(name: Token,
        superclass: ResolvedExpression?, // will be nil or variable
        methods: [ResolvedStatement])
    
    var description: String {
        switch self {
        case let .expression(re):
            return "EXPR: \(re)"
        case let .print(re):
            return "PRINT: \(re)"
        case let .block(rss):
            return "BLOCK: \(rss)"
        case let .`if`(re, then: thenrs, else: elsers):
            return "IF: \(re) THEN: \(thenrs) ELSE: \(String(describing: elsers))"
        case let .variable(name, initializer):
            return "VARIABLE: \(name) = \(String(describing: initializer))"
        case let .`while`(conditionre, bodyrs):
            return "WHILE: \(conditionre) \(bodyrs)"
        case let .function(rfd):
            return "FUNCTION: \(rfd)"
        case let .`return`(token, resexpression):
            return "RETURN: \(token) \(resexpression)"
        case let .class(name: name, superclass: superclass, methods: methods):
            return "CLASS: \(name) < \(String(describing: superclass)) - methods: \(methods)"
        }
    }
}

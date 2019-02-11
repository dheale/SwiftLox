//
//  Expression.swift
//  LoxFramework
//
//  Created by Dominic Heale on 30/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation
extension Double {
    func string() -> String {
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter.string(for: self) ?? "\(self)"
    }
}
enum Literal: CustomStringConvertible {
    case number(Double)
    case string(String)
    case bool(Bool)
    case function(Function)
    case `nil`
    
    case `class`(Class)
    case `instance`(Instance)
    
    var description: String {
        
        switch self {
        case let .number(d): return d.string()
        case let .string(s): return s
        case let .bool(b): return b ? "true" : "false"
        case .nil: return "nil"
            
        case let .class(c): return "\(c)"
        case let .function(fn): return fn.description
        case let .instance(i): return "\(i)"
        }
    }
}

indirect enum Expression {    
    case literal(Literal)
    case lambda(FunctionDefinition)

    case unary(Token, Expression)
    case binary(Expression, Token, Expression)
    
    /// Grouping is a bracketed expression: "( expr )"
    case grouping(Expression)
    
    /// Variable used in an expression context like print(a)
    /// Not in a statement context like var a = 3;
    case variable(name: Token)
    
    /// e.g. foo = 3
    case assign(name: Token, value: Expression)
    
    /// a short-circuiting logical operator || &&
    case logical(left: Expression, operator: Token, right: Expression)
    
    /// function call
    case call(callee: Expression, paren: Token, arguments: [Expression])
    
    // OO support
    case get(object: Expression, name: Token)
    case set(object: Expression, name: Token, value: Expression)
    case this(name: Token) // Lox uses 'this' for 'self' - like variable case
    case `super`(keyword: Token, method: Token)
}

indirect enum ResolvedExpression {
    case variable(name: Token, depth: Int)
    case assign(name: Token, value: ResolvedExpression, depth: Int)

    case lambda(ResolvedFunctionDefinition)
    
    case literal(Literal)

    case unary(Token, ResolvedExpression)
    case binary(ResolvedExpression, Token, ResolvedExpression)
    case grouping(ResolvedExpression)
    case logical(left: ResolvedExpression, operator: Token, right: ResolvedExpression)
    case call(callee: ResolvedExpression, paren: Token, arguments: [ResolvedExpression])
    
    // OO support
    case get(object: ResolvedExpression, name: Token)
    case set(object: ResolvedExpression, name: Token, value: ResolvedExpression)
    case this(name: Token, depth: Int)
    case `super`(keyword: Token, method: Token, depth: Int)
}


extension Literal: Equatable {
    static func == (lhs: Literal, rhs: Literal) -> Bool {
        switch (lhs, rhs) {
        case (.nil, .nil):
            return true
        case let (.string(left), .string(right)):
            return left == right
        case let (.number(left), .number(right)):
            return left == right
        case let (.bool(left), .bool(right)):
            return left == right
        case let (.function(a as UserFunction), .function(b as UserFunction)):
            return a === b
        case let (.class(a), .class(b)):
            return a === b
            
        case (.nil, _), (.bool, _), (.string, _), (.number, _), (.function, _), (.class, _), (.instance, _):
            return false
        }
    }
}

//
//  Expression+PrettyPrinted.swift
//  LoxFramework
//
//  Created by Dominic Heale on 05/02/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension Expression {
    func prettyPrinted() -> String {
        switch self {

        case .literal(let l):
            return "\(l)"
            
        case .binary(let l, let op, let r):
            return "(\(op.type) \(l.prettyPrinted()) \(r.prettyPrinted()))"
            
        case .unary(let op, let expr):
            return "(\(op.type) \(expr.prettyPrinted()))"
            
        case .grouping(let expr):
            return " (group  \(expr.prettyPrinted()) ) "
            
        case .variable(let name):
            return "(var: \(name))"
            
        case .assign(let name, let value):
            return "(assign: \(name) = \(value)"
            
        case .logical(let left, let `operator`, let right):
            return "(logical: \(left) \(`operator`) \(right)"
            
        case .call(let callee, let paren, let arguments):
            return ("call: \(callee) \(paren) [\(arguments)]")
            
        case let .lambda(fd):
            return ("lambda: \(fd)")
            
        case let .get(object, name):
            return ("get: \(object) \(name)")
        }
    }
}

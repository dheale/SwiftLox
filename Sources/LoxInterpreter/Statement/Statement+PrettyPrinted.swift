//
//  Statement+PrettyPrinted.swift
//  LoxInterpreter
//
//  Created by Dominic Heale on 17/11/2018.
//

import Foundation

extension Statement {
    func prettyPrinted() -> String {
        switch self {
        case let .expression(e):
            return e.prettyPrinted()
        case let .print(e):
            return "print: expression: \(e.prettyPrinted())"
        case let .variable(name: token, initializer: initializer):
            return "assign: var: \(token) = initializer: \(String(describing: initializer))"
        case let .block(statements):
            return "block: \(statements.map { $0.prettyPrinted() }.joined(separator: "\n"))"
        }
    }
}

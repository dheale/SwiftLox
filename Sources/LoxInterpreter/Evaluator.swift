//
//  Evaluator.swift
//  LoxFramework
//
//  Created by Dominic Heale on 26/09/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension ResolvedExpression {
    func evaluated(_ environment: Environment) throws -> Literal  {
        switch self {
        case .literal(let l):
            return l
            
        case .unary(let op, let expr):
            let right = try expr.evaluated(environment)
            
            switch op.type {
            case .bang:
                return .bool(!right.isTruthy)
            case .minus:
                guard case let .number(rightNumber) = right
                    else { throw RuntimeError(token: op, message: "Operand must be a number.") }

                return .number(-rightNumber)
            default: throw RuntimeError(token: op, message: "Unexpected unary operation.")
            }
            
        case .binary(let left, let op, let right):
            let lhs = try left.evaluated(environment)
            let rhs = try right.evaluated(environment)
            
            /// Deal with two numbers
            if case let .number(leftNumber) = lhs,
                case let .number(rightNumber) = rhs {
                switch op.type {
                case .plus:
                    return .number(leftNumber + rightNumber)
                case .minus:
                    return .number(leftNumber - rightNumber)
                case .slash:
                    return .number(leftNumber / rightNumber)
                case .star:
                    return .number(leftNumber * rightNumber)
                case .greater:
                    return .bool(leftNumber > rightNumber)
                case .greaterEqual:
                    return .bool(leftNumber >= rightNumber)
                case .less:
                    return .bool(leftNumber < rightNumber)
                case .lessEqual:
                    return .bool(leftNumber <= rightNumber)
                default: break
                }
            }
            
            /// Deal with two strings, only concatenation is supported
            if case let .string(leftString) = lhs,
                case let .string(rightString) = rhs,
                case .plus = op.type {
                return .string(leftString + rightString)
            }
            
            switch op.type {
            case .bangEqual: return .bool(lhs != rhs)
            case .equalEqual: return .bool(lhs == rhs)
                
            // By the time we got here, all correct binary operators with correct value
            // types are handled. Next handle correct operators with incorrect types.
            case .plus:
                throw RuntimeError(token: op, message: "Operands must be two numbers or two strings.")
            case .minus, .slash, .star, .greater, .greaterEqual, .less, .lessEqual:
                throw RuntimeError(token: op, message: "Operands must be numbers.")
            default: break
            }
            
            fatalError()

        case .grouping(let expression):
            return try expression.evaluated(environment)
            
        case let .variable(name, depth):
            return try environment.get(name: name, depth: depth)
            
        case let .assign(name, expression, depth):
            let value = try expression.evaluated(environment)
            try environment.assign(name: name, value: value, depth: depth)
            return value
            
        case .logical(let leftExpression, let `operator`, let rightExpression):
            let leftValue = try leftExpression.evaluated(environment)
            
            if `operator`.isType(.or) {
                if leftValue.isTruthy { return leftValue }
            } else {
                if !leftValue.isTruthy { return leftValue }
            }
            
            return try rightExpression.evaluated(environment)
            
        case .call(let callee, let paren, let arguments):
            
            let calleeValue = try callee.evaluated(environment)
            
            let argumentValues: [Literal] = try arguments.map {
                try $0.evaluated(environment)
            }
            
            guard let callable = calleeValue.callable(environment) else {
                throw RuntimeError(token: paren,
                                   message: "Can only call functions and classes.")
            }
            
            guard callable.arity == argumentValues.count else {
                throw RuntimeError(token: nil,
                                   message: "Expected \(callable.arity) arguments but got \(argumentValues.count).") // at [line \(paren.lineNumber)] 
            }

            do {
                return try callable.call(argumentValues)
            }
            catch let `return` as ReturnValue {
                return `return`.value
            }
            
        case let .lambda(definition):
            return .function(UserFunction(definition: definition,
                                          env: environment,
                                          isInitializer: false,
                                          description: "Unnamed function"))
            
        case let .get(object, name):
            let object = try object.evaluated(environment)
            
            guard case let .instance(instance) = object else {
                throw RuntimeError(token: name,
                                   message: "Only instances have properties.")
            }
            
            return try instance.get(name)
            
        case let .set(object: object, name: name, value: value):
            let object = try object.evaluated(environment)
            
            guard case let .instance(instance) = object else {
                throw RuntimeError(token: name,
                                   message: "Only instances have fields.")
            }

            let v = try value.evaluated(environment)
            instance.set(name, v)
            return v
            
        case .this(let name, let depth):
            return try environment.get(name: name, depth: depth)
            
        case let .super(_, method, depth):
             guard case let .class(superclass) = try environment.get(name: "super",
                                                                     depth: depth)
                else { fatalError("Got a non-class for 'super'.") }
            
            guard case let .instance(object) = try environment.get(name: "this",
                                                               depth: depth - 1)
                else { fatalError("Got a non-object for 'this'.") }
            
            guard let mtd = superclass.find(instance: object, method: method.lexeme) else {
                throw RuntimeError(token: nil,
                                   message: "Undefined property '\(method.lexeme)'.")
            }
            
            return .function(mtd)
        }
        
    }
}

extension Literal {
    func callable(_ env: Environment) -> Callable? {
        switch self {
        case let .function(f):
            return f as Callable
        case let .class(c):
            return c as Callable
        default:
            return nil
        }
    }
}

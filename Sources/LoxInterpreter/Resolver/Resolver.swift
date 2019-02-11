//
//  Resolver.swift
//  CommandLineKit
//
//  Created by Dominic Heale on 25/11/2018.
//

import Foundation

class Resolver {
    /// For the feature: detect e.g. 'return "at top level";'
    enum FunctionType {
        case function // regular function
        case method
        case initializer // init method on a class
    }
    
    private var enclosingFunctionType: FunctionType?
    private var currentFunctionType: FunctionType?
    
    /// For the feature: detect use of 'this' outside of instances
    enum ClassType {
        case `class`
        case subclass
    }
    
    var currentClassType: ClassType?
    
    
    // Scope is a dictionary of definitions to whether or not the name has
    // been declared (not yet initialized), or
    typealias Scope = [String : Bool]
    
    let interpreter: LoxInterpreter

    var scopes: [Scope] = []
    private(set) var currentFunction: FunctionType?
    
    init(interpreter: LoxInterpreter) {
        self.interpreter = interpreter
    }
    
    private func beginScope() { scopes.append([:])  }
    private func endScope()   { scopes.removeLast() }
    
    func resolve(_ statement: Statement) -> ResolvedStatement  {
        switch statement {
        case let .block(statements):
            beginScope()
            let resolvedStatements = statements.map(resolve)
            endScope()
            return .block(resolvedStatements)
            
        case let .variable(name: name, initializer: initializer):
            declare(name)
            let resolvedInit = initializer.flatMap { resolve($0) }
            define(name)
            return .variable(name: name, initializer: resolvedInit)

        case let .function(name: name, definition: definition):
            declare(name)
            
            // defining the name eagerly, before resolving the function’s body
            // lets a function recursively refer to itself inside its own body.
            define(name)
            
            return resolveFunction(name: name,
                                   definition: definition,
                                   type: .function)
            
        case let .expression(expression):
            return .expression(resolve(expression))
            
        case let .if(expr, then: then, else: elseExpr):

            return .if(resolve(expr),
                       then: resolve(then),
                       else: elseExpr.flatMap(resolve))
            
        case let .print(expr):
            return .print(resolve(expr))
        
        case let .return(token: token, expression: expr):
            if currentFunctionType == nil {
                interpreter.error(token, "Cannot return from top-level code.")
            }
            
            if case .some(.initializer) = currentFunctionType,
               case let .literal(l) = expr, l != .nil {
                interpreter.error(token, "Cannot return a value from an initializer.")
            }
            return .return(token: token, expression: resolve(expr))
        
        case let .`while`(condition: condition, body: body):
            return .`while`(condition: resolve(condition),
                            body: resolve(body))
        case let .class(name: name, superclass: superclass, methods: methods):
            let enclosingClassType = currentClassType
            currentClassType = .class
            
            declare(name)
            
            let resolvedSuperclass: ResolvedExpression? = {
                guard let superclass = superclass else { return nil }
                
                currentClassType = .subclass

                let result = resolve(superclass)
                
                // Define super, in a new scope that we will pop later
                scopes.append(["super": true])
                
                return result
            }()

            
            define(name)
            
            scopes.append(["this": true])
            
            let resolvedMethods = methods.map { (method: Statement) -> ResolvedStatement in
                guard case let .function(name, definition) = method else {
                    fatalError("TODO replace enum with protocols")
                }
                
                let type: FunctionType = {
                if name.lexeme == "init" {
                        return .initializer
                }
                    return .method
                }()
                
                return resolveFunction(name: name,
                                       definition: definition,
                                       type: type)
            }
            
            endScope()
            if resolvedSuperclass != nil {
                endScope()
            }
            
            currentClassType = enclosingClassType
            return .`class`(name: name,
                            superclass: resolvedSuperclass,
                            methods: resolvedMethods)
        }
    }
    
    
    func resolveFunction(name: Token,
                         definition: FunctionDefinition,
                         type: FunctionType = .function) -> ResolvedStatement {
        enclosingFunctionType = currentFunctionType
        currentFunctionType = type
        beginScope()
        
        for param in definition.parameters {
            declare(param)
            define(param)
        }
        
        let resolvedBody = definition.body.map { resolve($0) }
        endScope()
        currentFunctionType = enclosingFunctionType
        
        return .function(name: name,
                         definition:
            ResolvedFunctionDefinition(parameters: definition.parameters,
                                       body: resolvedBody))
    }

    func resolve(_ expression: Expression) -> ResolvedExpression {
        switch expression {
            
        case let .variable(name: name):
            // if is declared but not initialized
            if scopes.last?[name.lexeme] == false {
                interpreter.error(name, "Cannot read local variable in its own initializer.")
            }
            
            let depth = findFirstScopeContaining(name.lexeme)
            return .variable(name: name, depth: depth)

        case let .assign(name: name, value: epr):
            let value = resolve(epr)
            let depth = findFirstScopeContaining(name.lexeme)
            return .assign(name: name, value: value, depth: depth)
        
        case let .literal(literal):
            return .literal(literal)
            
        case let .unary(token, expression):
            return .unary(token, resolve(expression))
            
        case let .binary(left, op, right):
            return .binary(resolve(left), op, resolve(right))
            
        case let .grouping(expression):
            return .grouping(resolve(expression))
            
        /// a short-circuiting logical operator || &&
        case let .logical(left: left, operator: `operator`, right: right):
            return .logical(left: resolve(left),
                            operator: `operator`,
                            right: resolve(right))
            
        /// function call
        case let .call(callee: callee,
                       paren: paren,
                       arguments: arguments):
            let resCallee = resolve(callee)
            let resArgs = arguments.map { resolve($0) }
            return .call(callee: resCallee,
                         paren: paren,
                         arguments: resArgs)
        case let .lambda(definition):
            beginScope()
            
            for param in definition.parameters {
                declare(param)
                define(param)
            }
            
            let resolvedBody = definition.body.map { resolve($0) }
            endScope()

            let resolved = ResolvedFunctionDefinition(parameters: definition.parameters, body: resolvedBody)
            return .lambda(resolved)
            
        case let .get(object, name):
            return .get(object: resolve(object), name: name)
            
        case let .set(object, name, expression):
            return .set(object: resolve(object), name: name, value: resolve(expression))
        case let .this(name):
            if currentClassType == nil {
                interpreter.error(name, "Cannot use 'this' outside of a class.")
            }
            return .this(name: name,
                         depth: findFirstScopeContaining(name.lexeme))
            
        case let .super(keyword, method):
            switch currentClassType {
            case .none: interpreter.error(keyword, "Cannot use 'super' outside of a class.")
            case .some(.class): interpreter.error(keyword, "Cannot use 'super' in a class with no superclass.")
            case .some(.subclass): break
            }
            
            let depth = findFirstScopeContaining(keyword.lexeme)
            return .super(keyword: keyword, method: method, depth: depth)
        }
    }
    
    private func findFirstScopeContaining(_ name: String) -> Int {
        for (idx, scope) in scopes.reversed().enumerated() {
            if scope.keys.contains(name) {
                return idx
            }
        }
        
        return scopes.count
    }
    
    private func declare(_ name: Token) {
        guard let scope = scopes.last else { return }
        let key = name.lexeme
        
        if scope[key] != nil {
            interpreter.error(name, "Variable with this name already declared in this scope.")
        }
        
        scopes[scopes.count - 1][key] = false
    }
    
    private func define(_ name: Token) {
        if scopes.isEmpty { return }
        scopes[scopes.count - 1][name.lexeme] = true
    }
}

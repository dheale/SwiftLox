//
//  Callable.swift
//  LoxInterpreter
//
//  Created by Dominic Heale on 22/11/2018.
//

import Foundation

// In Lox, functions are callable, but also classes (for instantiation)
protocol Callable {
    var arity: Int { get }
    var description: String { get }
    
    @discardableResult
    func call(_ :[Literal]) throws -> Literal
}

//
//  Class.swift
//  CommandLineKit
//
//  Created by Dominic Heale on 27/12/2018.
//

import Foundation

// A Lox class
class Class
{
    init(name: String,
         superclass: Class?,
         methods: [String: Function]) {
        self.name = name
        self.superclass = superclass
        self.methods = methods
    }
    
    let name: String
    
    // have an array here so I can recursively use Class in Class
    // expect only one thing in the array though
    let superclass: Class?
    let methods: [String: Function]
    
    func find(instance: Instance, method name: String) -> Function? {

        if let meth = methods[name] as? UserFunction {
            return meth.bind(instance)
        }
        
        return superclass?.find(instance: instance, method: name)
    }
}

// You can call a class to create a new instance of it
extension Class: Callable {
    var arity: Int {
        return initializer?.arity ?? 0
    }
    
    func call(_ args: [Literal]) throws -> Literal {
        let instance = Instance(self)
        
        do {
            try initializer?.bind(instance).call(args)
        }
        catch _ as ReturnValue {
            return .instance(instance)
        }
        
        return .instance(instance)
    }
    
    var initializer: UserFunction? {
        return methods["init"] as? UserFunction
    }
}

extension Class: CustomStringConvertible {
    var description: String {
        return "\(name)"
    }
}

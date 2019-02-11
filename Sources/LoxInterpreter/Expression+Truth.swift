//
//  Expression+Truth.swift
//  LoxFramework
//
//  Created by Dominic Heale on 27/09/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension Literal {
    // Lox considers nil to be false
    // bools are their value, everything else is true
    var isTruthy: Bool {
        switch self {
        case .nil, .bool(false):
            return false

        case .bool(true),
             .number(_),
             .string(_),
             .function(_),
             .class(_),
             .instance(_):
            return true
        }
    }
}

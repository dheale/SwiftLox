//
//  RuntimeError.swift
//  LoxFramework
//
//  Created by Dominic Heale on 27/09/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

/// When we have a runtime error we throw this
/// The token has the location information
/// The message is just a string right now, but consider using something else
/// For example we could allow a richer object that would could have translations of the
/// meaning of the error message, or a richer context
public
struct RuntimeError: Error {
    static let returnCode: Int32 = 70
    
    let token: Token?
    let message: String
}

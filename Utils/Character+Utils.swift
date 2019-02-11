//
//  Character+Utils.swift
//  LoxFramework
//
//  Created by Dominic Heale on 25/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension Character {
    
    var isDigit: Bool {
        return Int(String(self)) != nil
    }
    
    func isIn(_ characterSet: CharacterSet) -> Bool {
        guard unicodeScalars.count == 1,
            let c = unicodeScalars.first else { return false }
        
        return characterSet.contains(c)
    }

    var isAlpha: Bool {
        return isIn(.letters)
    }
    
    var isAlphaNumeric: Bool {
        let underscore = CharacterSet(charactersIn: "_")
        return isIn(CharacterSet.alphanumerics.union(underscore))
    }
    
    var isQuote: Bool {
        return self == "\""
    }
    
}

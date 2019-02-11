//
//  String+Utils.swift
//  LoxMain
//
//  Created by Dominic Heale on 24/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
}

extension StringProtocol {
    var withoutSurroundingQuotes: String {
        var result = String(self)
        
        // Trim the surrounding quotes.
        if let f = result.first, f.isQuote {
            result.removeFirst()
        }
        
        if let l = result.last, l.isQuote {
            result.removeLast()
        }

        return result
    }
}

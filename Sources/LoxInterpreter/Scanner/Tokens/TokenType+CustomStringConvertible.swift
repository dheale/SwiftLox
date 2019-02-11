//
//  TokenType+CustomStringConvertible.swift
//  LoxMain
//
//  Created by Dominic Heale on 23/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

extension Token.TType: CustomStringConvertible
{
    public var description: String {
        switch self {
        case .leftParen: return "<leftParen>"
        case .rightParen: return "<rightParen>"
        case .leftBrace: return "<leftBrace>"
        case .rightBrace: return "<rightBrace>"
        case .comma: return "<comma>"
        case .dot: return "<dot>"
        case .minus: return "<minus>"
        case .plus: return "<plus>"
        case .semicolon: return "<semicolon>"
        case .slash: return "<slash>"
        case .star: return "<star>"
            
        // One or two character tokens.
        case .bang: return "<bang>"
        case .bangEqual: return "<bangEqual>"
            
        case .equal: return "<equal>"
        case .equalEqual: return "<equalEqual>"
        case .greater: return "<greater>"
        case .greaterEqual: return "<greaterEqual>"
        case .less: return "<less>"
        case .lessEqual: return "<lessEqual>"
            
        // Literals.
        case .identifier(let value): return "<identifier-\(value)>"
        case .string(let value): return "<string-\(value)>"
        case .number(let value): return "<number-\(value)>"
            
        // Keywords.
        case .and: return "<and>"
        case .`class`: return "<class>"
        case .`else`: return "<else>"
        case .`false`: return "<false>"
        case .fun: return "<fun>"
        case .`for`: return "<for>"
        case .`if`: return "<if>"
        case .`nil`: return "<nil>"
        case .`or`: return "<or>"
        case .print: return "<print>"
        case .`return`: return "<return>"
        case .`super`: return "<super>"
        case .`this`: return "<this>"
        case .`true`: return "<true>"
        case .`var`: return "<var>"
        case .`while`: return "<while>"
            
        case .eof: return "<eof>"
        }
    }
}

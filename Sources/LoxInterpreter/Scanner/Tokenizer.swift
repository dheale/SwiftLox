//
//  Scanner.swift
//  Lox
//
//  Created by Dominic Heale on 22/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

/// The scanner converts an input string
/// into a sequence of tokens
public class Tokenizer
{
    struct TokenizeError: Error {
        let line: Int
        let description: String
    }

    // The result of running a scan is either an array of tokens or
    // the error(s) that was/were found
    let source: String
    var hadError = false
    
    var start = 0
    var current = 0
    
    var line = 1
    
    public init(source: String) {
        self.source = source
    }
    
    
    /// Consumes the current character and returns it
    @discardableResult
    private func advance() -> Character {
        let c = current
        current = current + 1
        return source[c]
    }
    
    /// Only consumes the current character, if it matches
    private func match(_ expected: Character) -> Bool {
        guard isAtEnd == false,
            source[current] == expected
            else { return false }
        
        current += 1
        return true
    }
    
    private func peek() -> Character? {
        guard isAtEnd == false else { return nil } //"\u{0}" }
        
        return source[current]
    }
    
    private func peekNext() -> Character {
        if current + 1 >= source.count { return "\u{0}" }
        return source[current + 1]
    }
    
    /// Represents the current 'window' onto the source that we are processing
    private var currentString: Substring {
        let from = source.index(source.startIndex, offsetBy: start)
        let to   = source.index(source.startIndex, offsetBy: current)

        return source[from ..< to]
    }
    
    private func string() throws -> Token? {
        while peek() != "\"" && !isAtEnd {
            if peek() == "\n" { line += 1 }
            advance()
        }
        
        guard isAtEnd == false else {
            throw TokenizeError(line: line, description: "Unterminated string.")
        }

        advance() // over the closing "
        return token(.string(currentString.withoutSurroundingQuotes))
    }
    
    private func number() throws -> Token? {
        while let p = peek(), p.isDigit {
            advance()
        }
        
        // Look for a fractional part.
        if peek() == "." && peekNext().isDigit {
            // Consume the "."
            advance()
        }
        
        while let p = peek(), p.isDigit { advance() }
        
        guard let n = Double(currentString) else {
            throw TokenizeError(line: line, description: "can't recognize a number")
        }
        return token(.number(n))
    }
    
    private func identifier() -> Token? {
        while let p = peek(), p.isAlphaNumeric { advance() }
        guard let type = Token.TType(identifierOrReservedWord: currentString) else { return nil }
        
        return token(type)
    }
    
    
    private func scanToken() throws -> Token? {
        let c = advance()
        
        if let singleCharToken = Token.TType(character: c) {
            return token(singleCharToken)
        }
        
        switch c {
        case "!": if match("=") { return token(.bangEqual) }
            return token(.bang)
        case "=": if match("=") { return token(.equalEqual) }
            return token(.equal)
        case "<": if match("=") { return token(.lessEqual) }
            return token(.less)
        case ">": if match("=") { return token(.greaterEqual) }
            return token(.greater)
            
        case "/":
            if match("/") {
                // A comment goes until the end of the line.
                while peek() != "\n"
                    && !isAtEnd {
                        advance()
                }
                return nil // no token for a comment
            } else {  // just a single slash
                return token(.slash)
            }
            
        case " ", "\r", "\t":
            // Ignore whitespace.
            return nil
            
        case "\n":
            line += 1
            return nil

        case "\"":
            return try string()

        default:
            // If we find the start of a digit then go off and recognize it
            if c.isDigit {
                return try number()
            }
            if c.isAlpha {
                // returns a token representing an identifer, inc reserved words
                return identifier()
            }
        }
        
        throw TokenizeError(line: line, description: "Unexpected character.") // \(c)")
    }
    
    private var isAtEnd: Bool {
        return current >= source.count
    }
    
    private func error(_ message: String, at line: Int) {
        hadError = true
        
        fputs("[line \(line)] Error: \(message)", stderr)
    }
    
    private var shouldKeepGoing: Bool {
        return !isAtEnd // and perhaps the number of errors is not too many
    }
    
    private func token(_ type: Token.TType) -> Token {
        let lexeme = type == .eof ? "" : String(currentString)
        
        return Token(type: type,
                     lineNumber: line,
                     lexeme: lexeme)
    }
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    /// - Throws: Error if couldn't convert to a bunch of tokens
    func tokenize() throws -> [Token] {
        var tokens = [Token]()
        var tokenizeError: Error?
        
        while shouldKeepGoing {
            // We are at the beginning of the next lexeme.
            start = current
            do {
                if let token = try scanToken() {
                    tokens.append(token)
                }
            }
            catch let e as TokenizeError {
                tokenizeError = e
                error(e.description, at: e.line)
            }
        }
        
        guard hadError == false else {
            throw tokenizeError!
        }
        
        tokens.append(token(.eof))
        return tokens
    }
    
}

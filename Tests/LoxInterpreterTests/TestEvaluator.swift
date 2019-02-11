//
//  TestEvaluator.swift
//  LoxInterpreterTests
//
//  Created by Dominic Heale on 27/09/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import Foundation

import XCTest
@testable import LoxInterpreter

class TestEvaluator: XCTestCase {
    
    func ensure(_ types: [Token.TType],
                is expectation: Literal) {
        
        var withSemiEOF = types
        withSemiEOF.append(.semicolon)
        withSemiEOF.append(.eof)
        
        XCTAssert(
            evaluate(withSemiEOF.map {
            Token(type: $0, lineNumber: 1, lexeme: String(describing: $0))
        }) == .some(expectation))
    }
    
    func evaluate(_ tokens: [Token]) -> Literal? {
        let interpreter = LoxInterpreter()
        
        let p = Parser(tokens: tokens, interpreter: interpreter)
        do {
            guard let t = try p.parse().first else {
                XCTFail("Couldn't parse - Expected tokens result")
                return nil
            }
            
            guard case let Statement.expression(e) = t else {
                XCTFail("Expected statement expression")
                return nil
            }
            
            let re = Resolver(interpreter: interpreter).resolve(e)
            return try re.evaluated(Environment.global)
        }
        catch {
            XCTFail(error.localizedDescription)
            return nil
        }
    }
    

    func testEvaluateMissingSemicolonTrueLiteral() {
        let p = Parser(tokens: [ Token(type: .true, lineNumber: 1, lexeme: "true"),
                                 Token(type: .eof, lineNumber: 1, lexeme: "")
            ], interpreter: LoxInterpreter() )
        do {
            let a = try p.parse()
            XCTAssert(a.count == 0)
        } catch {
            XCTFail()
        }
    }

    func testEvaluateTrueLiteral() {
        ensure([ .true ], is: .bool(true))
    }
    
    func testEvaluateNotTrueLiteral() {
        ensure([ .bang, .true ], is: .bool(false))
        ensure([ .bang, .false ], is: .bool(true))
        ensure([ .bang, .bang, .true ], is: .bool(true))
    }

    func testALiteralNumberEvaluatesToItself() {
        ensure([ .number(42.0) ], is: .number(42))
    }
    
    func testALiteralStringEvaluatesToItself() {
        ensure([ .string("42.0") ], is: .string("42.0"))
    }
    
    func testEvaluateUnaryMinusNumberLiteral() {
        ensure([ .minus, .number(42.0) ], is: .number(-42.0))
    }

    func testEvaluateTwoLessThanThreeIsTrue() {
        ensure([ .number(2), .less, .number(3) ], is: .bool(true))
    }

    func testEvaluateTwoLessThanOneIsFalse() {
        ensure([ .number(2), .less, .number(1) ], is: .bool(false))
    }
    
    func testStringConcatenation() {
        ensure([ .string("A"), .plus, .string("B") ], is: .string("AB"))
    }

    func testGroupingParenthesis() {
        // (1 + 3) * 2
        // should be 8 = 4*2, not 7 = 1+6
        ensure([
            .leftParen, .number(1), .plus, .number(3), .rightParen,
            .star,
            .number(2)
            ], is: .number(8) )
    }
    

    func testGroupingParens2() {
        // 4 * (3 + 2) => 20
        ensure([
            .number(4),
            .star,
            .leftParen, .number(3), .plus, .number(2), .rightParen
            ], is: .number(20) )
    }
    
    func testGroupingParens3() {
        // 3 + (2 * (12 - 3)) => 21
        ensure([
            .number(3), .plus,
            .leftParen, .number(2), .star,
                        .leftParen, .number(12), .minus, .number(3), .rightParen,
            .rightParen

            ], is: .number(21))
    }

    func ensure(_ types: [Token.TType], errors:(Error) -> Void) {
        
        var withSemiEOF = types
        withSemiEOF.append(.semicolon)
        withSemiEOF.append(.eof)
        
        do {
            let tokens = withSemiEOF.map {
                Token(type: $0, lineNumber: 1, lexeme: String(describing: $0))
            }
            
            let interpreter = LoxInterpreter()
                
            let p = Parser(tokens: tokens, interpreter: interpreter )
                guard let t = try p.parse().first else {
                    XCTFail("Couldn't parse - Expected tokens result")
                    return
                }
                
                guard case let Statement.expression(e) = t else {
                    XCTFail("Expected statement expression")
                    return
                }
                
                let re = Resolver(interpreter: interpreter).resolve(e)
                try _ = re.evaluated(Environment.global)
                XCTFail()
        }
        catch {
            errors(error)
        }
    }

    func testFailUnaryMinusWithString() {
        ensure([
            .minus, .string("42.0")
        ]) { error in
            XCTAssert(error is RuntimeError)
            XCTAssert((error as! RuntimeError).message == "Operand must be a number.")
        }
    }
    
    func testEvaluateAPlus2ThrowsRuntimeError() {
        ensure([
            .string("A"), .plus, .number(2)
        ]) { error in
            XCTAssert(error is RuntimeError)
            XCTAssert((error as! RuntimeError).message == "Operands must be two numbers or two strings.")
        }
    }

    func testMisMatchedParens1() {
        let interpreter = LoxInterpreter()
        
        let p = Parser(tokens: [
            Token(type: .rightParen,
                  lineNumber: 1,
                  lexeme: ")")
            ], interpreter: interpreter)
        do {
            let t = try p.parse()
            XCTAssert(t.count == 0)
        }
        catch {
            XCTFail("")
        }
    }
}

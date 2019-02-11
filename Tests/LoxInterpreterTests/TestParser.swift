//
//  TestParser.swift
//  TestTokenizer
//
//  Created by Dominic Heale on 06/02/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import XCTest
@testable import LoxInterpreter

class TestParser: XCTestCase {
    func ensure(_ tokenTypes: [Token.TType],
                is expected: String) {
        
        let tokens = (tokenTypes + [.semicolon, .eof]).map {
            Token(type: $0, lineNumber: 1, lexeme: String(describing: $0))
        }
        
        let p = Parser(tokens: tokens,
                       interpreter: LoxInterpreter())
        
        XCTAssert(try p.parse().first!.prettyPrinted() == expected)
    }
    
    
    func testEqualTrue() {
        ensure([.true, .equalEqual, .true], is: "(<equalEqual> true true)")
    }

    func testEqualTrue2() {
        ensure([.false, .equalEqual, .true, .equalEqual, .true],
               is: "(<equalEqual> (<equalEqual> false true) true)")
    }

    func testLiteralNumber() {
        ensure([.number(123.0)], is: "123")
    }

    func testOnePlusOne() {
        ensure([.number(1.0), .plus, .number(1.0)],
               is: "(<plus> 1 1)")
    }

    func testOnePlusOnePlusOne() {
        ensure([.number(1.0), .plus,
                .number(2.0), .plus,
                .number(3.0)],
               is: "(<plus> (<plus> 1 2) 3)")
    }

    func testOnePlusTwoTimesThree() {
        ensure([ .number(1.0),
                 .plus,
                 .number(2.0),
                 .star,
                 .number(3.0)],
               is: "(<plus> 1 (<star> 2 3))")
    }

    func testOnePlusTwoTimesThreeMinusTwoTimesTwo() {
        ensure([.number(1.0),
                .plus,
                .number(2.0),
                .star,
                .number(3.0),
                .minus,
                .number(2.0),
                .star,
                .number(2.0)],
               is: "(<minus> (<plus> 1 (<star> 2 3)) (<star> 2 2))")
    }

    func testFourTimesBrackets2PlusSix() {
        ensure([ .number(4.0),
                 .star,
                 .leftParen,
                 .number(2.0),
                 .plus,
                 .number(6.0),
                 .rightParen,],
               is: "(<star> 4  (group  (<plus> 2 6) ) )")
    }

}

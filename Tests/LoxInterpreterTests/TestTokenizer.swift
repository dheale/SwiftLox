//
//  TestScanner.swift
//  TestTokenizer
//
//  Created by Dominic Heale on 23/01/2018.
//  Copyright © 2018 Dominic Heale. All rights reserved.
//

import XCTest
@testable import LoxInterpreter

class TestTokenizer: XCTestCase {
    @discardableResult
    func ensure(_ source: String,
                is expectedTypes: [Token.TType]) -> [Token] {
        let tokenizer = Tokenizer(source: source)
        
        guard let tokens = try? tokenizer.tokenize() else {
            XCTFail("Scan failed")
            return []
        }
        
        XCTAssert(tokens.map { $0.type } == expectedTypes)
        return tokens
    }
    
    
    func testSingleAndTwoCharTokens() {
        let expected: [Token.TType] = [
            .bang,
            .bangEqual,
            .less,
            .greater,
            .lessEqual,
            .eof
        ]
        
        let tokens = ensure("!!=<><=", is: expected)
        let expectedLineNumbers = expected.map { _ in return 1 }
        
        let expectedLexemes = [
            "!",
            "!=",
            "<",
            ">",
            "<=",
            ""
        ]

        XCTAssert(tokens.map { $0.lineNumber } == expectedLineNumbers)
        XCTAssert(tokens.map { $0.lexeme } == expectedLexemes)
    }

    func testSlashComment() {
        ensure(
"""
// This is a comment print "Hello world!";
!
""", is: [ .bang, .eof ])
    }

    func testStringLiteral() {
        ensure("\"Hello world\"", is: [
            .string("Hello world"),
            .eof
        ])
    }

    func testScanHelloWorld() {
        ensure("print \"Hello world!\";", is:
            [
                .print,
                .string("Hello world!"),
                .semicolon,
                .eof
            ])
    }

    func testDigit() {
        ensure("3.14159", is: [
            .number(3.14159),
            .eof
        ])
    }

    func testDigitFollowedByDot() {
        ensure("3.14159.1234", is: [
            .number(3.14159),
            .dot,
            .number(1234),
            .eof
        ])
    }

}

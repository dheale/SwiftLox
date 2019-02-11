import XCTest

import LoxTests

var tests = [XCTestCaseEntry]()
tests += LoxTests.allTests()
XCTMain(tests)
import XCTest

import dns_sdTests

var tests = [XCTestCaseEntry]()
tests += dns_sdTests.allTests()
XCTMain(tests)

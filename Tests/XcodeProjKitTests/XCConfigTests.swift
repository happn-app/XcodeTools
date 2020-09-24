import Foundation
import XCTest

@testable import XcodeProjKit



class XCConfigTests : XCTestCase {
	
	func testOptionalImportWithSpaceFailure() throws {
		XCTAssertThrowsError(try XCConfig.Line(lineString: #"#include ? "hello""#))
	}
	
	func testWeirdSpacings() throws {
		do {let testString = "\t  ";                                                XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
		do {let testString = " \t TEST_LINE_PARSING =hello";                        XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
		do {let testString = "\t TEST_LINE_PARSING2\t=\t\thello\t// comment";       XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
		do {let testString = "\t TEST_LINE_PARSING3 =\thello\t  // comment// sd  "; XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
		do {let testString = "TEST_LINE_PARSING4=hello// comment\t// sd\t\t";       XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
		do {let testString = "TEST_LINE_PARSING5=//";                               XCTAssertEqual(testString, try XCConfig.Line(lineString: testString).lineString)}
	}
	
}

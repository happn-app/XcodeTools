import Foundation
import XCTest

@testable import XcodeProjKit



class VariableResolutionTests : XCTestCase {
	
	let refSettings = CombinedBuildSettings(targetName: nil, configurationName: "Test", buildSettingsLevels: [
		BuildSettings(rawBuildSettings: ["VALUE_1": "Value 1"]),
		BuildSettings(rawBuildSettings: ["VALUE_2": "Value 2"]),
		BuildSettings(rawBuildSettings: ["VALUE_12": "Value 12"]),
		BuildSettings(rawBuildSettings: ["VAR": "NUMBER2"]),
		BuildSettings(rawBuildSettings: ["NUMBER1": "1"]),
		BuildSettings(rawBuildSettings: ["NUMBER2": "2"])
	])
	
	func testSimpleResolutionWithParenthesis() throws {
		let actual = refSettings.resolveVariables(in: "prefix $(VALUE_1) suffix")
		let expected = "prefix Value 1 suffix"
		XCTAssertEqual(actual, expected)
	}
	
	func testEmbeddedOnceResolution() throws {
		let actual = refSettings.resolveVariables(in: "prefix $(VALUE_$(NUMBER2)) suffix")
		let expected = "prefix Value 2 suffix"
		XCTAssertEqual(actual, expected)
	}
	
	func testEmbeddedOnceTwoTimesResolution() throws {
		let actual = refSettings.resolveVariables(in: "prefix $(VALUE_$(NUMBER1)$(NUMBER2)) suffix")
		let expected = "prefix Value 12 suffix"
		XCTAssertEqual(actual, expected)
	}
	
	func testEmbeddedTwiceResolution() throws {
		let actual = refSettings.resolveVariables(in: "prefix $(VALUE_$($(VAR))) suffix")
		let expected = "prefix Value 2 suffix"
		XCTAssertEqual(actual, expected)
	}
	
	func testSimpleResolutionWithoutParenthesis() throws {
		let actual = refSettings.resolveVariables(in: "prefix $VALUE_1 suffix")
		let expected = "prefix Value 1 suffix"
		XCTAssertEqual(actual, expected)
	}
	
}

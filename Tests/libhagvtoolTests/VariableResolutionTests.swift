import Foundation
import XCTest

@testable import libhagvtool



class VariableResolutionTests : XCTestCase {
	
	let refSettings = CombinedBuildSettings(targetName: nil, configurationName: "Test", buildSettingsLevels: [BuildSettings(rawBuildSettings: ["VALUE": "Value"])])
	
	func testSimpleResolutionWithParenthesis() throws {
		let actual = refSettings.resolveVariables(in: "prefix $(VALUE) suffix")
		let expected = "prefix Value suffix"
		XCTAssertEqual(actual, expected)
	}
	
	func testSimpleResolutionWithoutParenthesis() throws {
		let actual = refSettings.resolveVariables(in: "prefix $VALUE suffix")
		let expected = "prefix Value suffix"
		XCTAssertEqual(actual, expected)
	}
	
}

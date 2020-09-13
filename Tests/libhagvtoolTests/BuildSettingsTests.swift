import Foundation
import XCTest

@testable import libhagvtool



class BuildSettingsTests : XCTestCase {
	
	func testParameterParsingWithComma() throws {
		let actual = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*,arch=*][variant=debug]": ""], allowCommaSeparatorForParameters: true)
		let expected1 = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*][arch=*][variant=debug]": ""], allowCommaSeparatorForParameters: true)
		let expected2 = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*][arch=*][variant=debug]": ""], allowCommaSeparatorForParameters: false)
		compareBuildSettings(expected1, actual)
		compareBuildSettings(expected2, actual)
	}
	
	func testParameterParsingFailWithoutComma() throws {
		let expected = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*]": ""], allowCommaSeparatorForParameters: false)
		let actual = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*][arch=*,this_is_junk": ""], allowCommaSeparatorForParameters: false)
		compareBuildSettings(expected, actual)
	}
	
	func testParameterParsingFailWithComma() throws {
		let expected = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*]": ""], allowCommaSeparatorForParameters: true)
		let actual = BuildSettings(rawBuildSettings: ["MY_BUILD_SETTING[skd=*][arch=*,this_is_junk": ""], allowCommaSeparatorForParameters: true)
		compareBuildSettings(expected, actual)
	}
	
	private func compareBuildSettings(_ s1: BuildSettings, _ s2: BuildSettings) {
		XCTAssertEqual(s1.settings.map{ $0.key }, s2.settings.map{ $0.key })
	}
	
}

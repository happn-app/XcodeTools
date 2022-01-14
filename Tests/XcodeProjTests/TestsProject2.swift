import Foundation
import XCTest

@testable import XcodeProj



final class TestsProject2 : XCTestCase {
	
	let xcodeprojURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("project2").appendingPathComponent("project2.xcodeproj")
	
	func testIterateFiles() throws {
		let xcodeproj = try XcodeProj(xcodeprojURL: xcodeprojURL)
		try xcodeproj.iterateFiles{ url, fileType in
			print(url, fileType)
		}
	}
	
}

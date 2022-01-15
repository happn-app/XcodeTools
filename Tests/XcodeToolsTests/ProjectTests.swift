import Foundation
import XCTest

import CLTLogger
import Logging

@testable import XcodeTools



final class ProjectTests : XCTestCase {
	
	override class func setUp() {
		super.setUp()
		
		/* Setup the logger */
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		var logger = Logger(label: "main")
		logger.logLevel = .trace
		XcodeToolsConfig.logger = logger
	}
	
	let project2URL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("project2").appendingPathComponent("project2.xcodeproj")
	
	func testProject2() throws {
		let project = try Project(xcodeprojURL: project2URL)
		try XCTAssertEqual(project.targets.count, 4)
	}
	
}

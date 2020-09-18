import Foundation
import XCTest

@testable import XcodeProjKit



class TestAllProjects : XCTestCase {
	
	let testProjectsURL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("projects")
	
	func testReserialization() throws {
		let fm = FileManager.default
		guard let de = fm.enumerator(atPath: testProjectsURL.path) else {
			throw XcodeProjKitError(message: "Cannot get dir enumerator at path \(testProjectsURL.path)")
		}
		
		while let f = de.nextObject() as! String? {
			guard f.hasSuffix(".xcodeproj") ||  f.hasSuffix(".xcodeproj/") else {
				continue
			}
			
			let xcodeprojURL = URL(fileURLWithPath: f, isDirectory: true, relativeTo: testProjectsURL)
			print("Testing project at path \(xcodeprojURL.path)")
			
			let xcodeproj = try XcodeProj(xcodeprojURL: xcodeprojURL)
			let originalContents = try Data(contentsOf: xcodeproj.pbxprojURL)
			try XCTAssertEqual(originalContents, Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8))
			
			/* Uncomment the line below to write the reserialized files to disk to
			 * find diffs using git. */
//			try Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8).write(to: xcodeproj.pbxprojURL)
		}
	}
	
}

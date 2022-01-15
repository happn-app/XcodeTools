import Foundation
import XCTest

@testable import SPMProj



final class SPMProjTests : XCTestCase {
	
	let package1URL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("package1")
	
	func testPackage1() throws {
		let proj = try SPMProj(url: package1URL)
		
	}
	
}

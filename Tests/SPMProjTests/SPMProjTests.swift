import Foundation
import XCTest

@testable import SPMProj



final class SPMProjTests : XCTestCase {
	
	let package1URL = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData").appendingPathComponent("package1")
	
	func testPackage1() throws {
		let proj = try SPMProj(url: package1URL)
		XCTAssertEqual(Set(proj.targets.map(\.name)), Set(arrayLiteral: "package1", "package1Tests"))
		XCTAssertEqual(Set((proj.targets.first{ $0.name == "package1"      }?.sources) ?? []), Set(arrayLiteral: package1URL.appendingPathComponent("Sources").appendingPathComponent("package1").appendingPathComponent("Package1.swift")))
		XCTAssertEqual(Set((proj.targets.first{ $0.name == "package1Tests" }?.sources) ?? []), Set(arrayLiteral: package1URL.appendingPathComponent("Tests").appendingPathComponent("package1Tests").appendingPathComponent("Package1Tests.swift")))
	}
	
}

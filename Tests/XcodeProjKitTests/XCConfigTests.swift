import Foundation
import XCTest

@testable import XcodeProjKit



class XCConfigTests : XCTestCase {
	
	func testOptionalImportWithSpaceFailure() throws {
		XCTAssertThrowsError(try XCConfig.Line(lineString: #"#include ? "hello""#))
	}
	
}

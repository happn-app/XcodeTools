import CryptoKit
import Foundation
import XCTest

import CLTLogger
import Logging
import SystemPackage

@testable import SourceBuilder



class SourceBuilderTests : XCTestCase {
	
	override class func setUp() {
		LoggingSystem.bootstrap{ _ in
			var l = CLTLogger()
			l.logLevel = .trace
			return l
		}
	}
	
	func testDownloadFile() async throws {
		let tmpFolder = FilePath(FileManager.default.temporaryDirectory)!
		let tmpFile = tmpFolder.lexicallyResolving(FilePath(UUID().uuidString))!
		defer {_ = try? FileManager.default.removeItem(at: tmpFile.url)}
		
		let downloadPhase = try DownloadFilePhase(
			urlTemplate: "https://{{ host }}/constant.{{ extension }}", variables: ["host": "frostland.fr", "extension": "txt"],
			destination: tmpFile, expectedHash: ("73475cb40a568e8da8a045ced110137e159f890ac4da883b6b17dc651b3a8049", AnyHasher(t: SHA256.self))
		)
		let skip1 = try await downloadPhase.canBeSkipped; XCTAssertFalse(skip1)
		
		let files = try await downloadPhase.execute();    XCTAssertEqual(files, [tmpFile])
		let skip2 = try await downloadPhase.canBeSkipped; XCTAssertTrue(skip2)
		
		try Data().write(to: tmpFile.url)
		let skip3 = try await downloadPhase.canBeSkipped; XCTAssertFalse(skip3)
		
		_ = try await downloadPhase.execute()
		let skip4 = try await downloadPhase.canBeSkipped; XCTAssertTrue(skip4)
	}
	
}

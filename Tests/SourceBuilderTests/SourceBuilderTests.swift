import Crypto
import Foundation
import XCTest

import CLTLogger
import Logging
import SystemPackage

import Utils

@testable import SourceBuilder



class SourceBuilderTests : XCTestCase {
	
	override class func setUp() {
		super.setUp()
		
		LoggingSystem.bootstrap{ _ in
			var l = CLTLogger()
			l.logLevel = .trace
			return l
		}
	}
	
	func testDownloadFile() throws {
		/* While swift on Linux does not have proper async support in XCTest, we
		 * have to put the LINUXASYNC blocks. When Linux is ok, we’ll simply
		 * remove these blocks and make the test async. */
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{do{
			/* LINUXASYNC STOP --------- */
			
			let tmpFolder = FilePath(FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))!
			let expectedDestinationFile = tmpFolder.appending("constant.txt")
			defer {_ = try? FileManager.default.ensureDirectoryDeleted(path: tmpFolder)}
			
			try FileManager.default.ensureDirectory(path: tmpFolder)
			
			let downloadPhase = try DownloadFilePhase(
				urlTemplate: "https://{{ host }}/constant.{{ extension }}", variables: ["host": "frostland.fr", "extension": "txt"],
				destinationFolder: tmpFolder, expectedHash: ("73475cb40a568e8da8a045ced110137e159f890ac4da883b6b17dc651b3a8049", AnyHasher(t: SHA256.self))
			)
			let skip1 = try await downloadPhase.canBeSkipped; XCTAssertFalse(skip1)
			
			let files = try await downloadPhase.execute();    XCTAssertEqual(files, [expectedDestinationFile])
			let skip2 = try await downloadPhase.canBeSkipped; XCTAssertTrue(skip2)
			
			try Data().write(to: expectedDestinationFile.url)
			let skip3 = try await downloadPhase.canBeSkipped; XCTAssertFalse(skip3)
			
			_ = try await downloadPhase.execute()
			let skip4 = try await downloadPhase.canBeSkipped; XCTAssertTrue(skip4)
			
			/* LINUXASYNC START --------- */
			group.leave()
		} catch {XCTFail("Error thrown during async test: \(error)"); group.leave()}}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testUntar() throws {
		/* While swift on Linux does not have proper async support in XCTest, we
		 * have to put the LINUXASYNC blocks. When Linux is ok, we’ll simply
		 * remove these blocks and make the test async. */
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{do{
			/* LINUXASYNC STOP --------- */
			
			XCTAssertThrowsError(try UntarPhase(unarchivedFile: "/a/b/c"))
			XCTAssertEqual(try UntarPhase(unarchivedFile: "/a/b/c.tgz").destinationFolder,     FilePath("/a/b/c"))
			XCTAssertEqual(try UntarPhase(unarchivedFile: "/a/b/c.tar.gz").destinationFolder,  FilePath("/a/b/c"))
			XCTAssertEqual(try UntarPhase(unarchivedFile: "/a/b/c.tar.bz2").destinationFolder, FilePath("/a/b/c"))
			XCTAssertEqual(try UntarPhase(unarchivedFile: "/a/b/c.tar.bob").destinationFolder, FilePath("/a/b/c"))
			XCTAssertEqual(try UntarPhase(unarchivedFile: "/a/b/c.1.bob").destinationFolder,   FilePath("/a/b/c.1"))
			
			let tarPhase = try UntarPhase(unarchivedFile: Self.filesPath.appending("test-0.1.tar.bz2"), stripComponents: 1, verifyNoLostFilesFromStrip: true)
			try await tarPhase.execute()
			
			/* LINUXASYNC START --------- */
			group.leave()
		} catch {XCTFail("Error thrown during async test: \(error)"); group.leave()}}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	private static var testsDataPath: FilePath {
		return FilePath(#filePath)
			.removingLastComponent().removingLastComponent().removingLastComponent()
			.appending("TestsData")
	}
	
	private static var scriptsPath: FilePath {
		return testsDataPath.appending("scripts")
	}
	
	private static var filesPath: FilePath {
		return testsDataPath.appending("files")
	}
	
}

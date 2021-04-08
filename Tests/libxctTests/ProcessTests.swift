import Foundation
import XCTest

import CLTLogger
import Logging
import StreamReader
import SystemPackage

@testable import libxct



final class ProcessTests : XCTestCase {
	
	override class func setUp() {
		super.setUp()
		
		/* Setup the logger */
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		var logger = Logger(label: "main")
		logger.logLevel = .trace
		LibXctConfig.logger = logger
		
		/* Let’s set the xct exec path env var (some methods need it) */
		setenv(LibXctConstants.envVarNameExecPath, productsDirectory.path, 1)
	}
	
	func testProcessLaunchAndStreamStdin() throws {
		struct ReadError : Error {}
		let fileURL = URL(fileURLWithPath: #filePath)
			.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			.appendingPathComponent("TestsData").appendingPathComponent("files").appendingPathComponent("three_lines.txt")
		let fd = try FileDescriptor.open(fileURL.path, .readOnly)
		let fileContents = try fd.closeAfter{ () -> String in
			guard let r = try String(data: FileDescriptorReader(stream: fd, bufferSize: 256, bufferSizeIncrement: 128).readDataToEnd(), encoding: .utf8) else {
				throw ReadError()
			}
			return r
		}
		
		var linesByFd = [FileDescriptor: [String]]()
		let (terminationStatus, terminationReason) = try Process.spawnAndStream(
			"/bin/cat", args: [],
			stdin: FileDescriptor.open(fileURL.path, .readOnly),
			stdoutRedirect: .capture, stderrRedirect: .capture, signalsToForward: [],
			outputHandler: { line, fd in
				linesByFd[fd, default: []].append(line)
			}
		)
		
		XCTAssertEqual(terminationStatus, 0)
		XCTAssertEqual(terminationReason, .exit)
		
		XCTAssertNil(linesByFd[FileDescriptor.xctStderr])
		XCTAssertEqual(linesByFd[FileDescriptor.xctStdout, default: []].joined(), fileContents)
	}
	
	func testProcessLaunchAndStreamStdoutAndStderr() throws {
		struct ReadError : Error {}
		let scriptURL = URL(fileURLWithPath: #filePath)
			.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			.appendingPathComponent("TestsData").appendingPathComponent("scripts").appendingPathComponent("slow_and_interleaved_output.swift")
		
		let n = 3 /* Not lower than 2 to get fdSwitchCount high enough */
		let t = 0.25
		
		var fdSwitchCount = 0
		var previousFd: FileDescriptor?
		var linesByFd = [FileDescriptor: [String]]()
		let (terminationStatus, terminationReason) = try Process.spawnAndStream(
			scriptURL.path, args: ["\(n)", "\(t)"], stdin: nil,
			stdoutRedirect: .capture, stderrRedirect: .capture, signalsToForward: [],
			outputHandler: { line, fd in
				if previousFd != fd {
					fdSwitchCount += 1
					previousFd = fd
				}
				linesByFd[fd, default: []].append(line)
			}
		)
		
		XCTAssertGreaterThan(fdSwitchCount, 2)
		
		XCTAssertEqual(terminationStatus, 0)
		XCTAssertEqual(terminationReason, .exit)
		
		let expectedStdout = (1...n).map{ String(repeating: "*", count: $0)           }.joined(separator: "\n") + "\n"
		let expectedStderr = (1...n).map{ String(repeating: "*", count: (n - $0 + 1)) }.joined(separator: "\n") + "\n"
		
		XCTAssertEqual(linesByFd[FileDescriptor.xctStdout, default: []].joined(), expectedStdout)
		XCTAssertEqual(linesByFd[FileDescriptor.xctStderr, default: []].joined(), expectedStderr)
	}
	
	/** Returns the path to the built products directory. */
	private static var productsDirectory: URL {
		#if os(macOS)
		for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
			return bundle.bundleURL.deletingLastPathComponent()
		}
		fatalError("couldn't find the products directory")
		#else
		return Bundle.main.bundleURL
		#endif
	}
	
}

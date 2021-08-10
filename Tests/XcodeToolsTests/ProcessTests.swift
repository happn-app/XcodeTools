import Foundation
import XCTest

import CLTLogger
import Logging
import StreamReader
import SystemPackage

@testable import XcodeTools



final class ProcessTests : XCTestCase {
	
	override class func setUp() {
		super.setUp()
		
		/* Setup the logger */
		LoggingSystem.bootstrap{ _ in CLTLogger() }
		var logger = Logger(label: "main")
		logger.logLevel = .trace
		XcodeToolsConfig.logger = logger
		
		/* Let’s set the xct exec path env var (some methods need it) */
		setenv(XcodeToolsConstants.envVarNameExecPath, productsDirectory.path, 1)
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
		
		XCTAssertNil(linesByFd[FileDescriptor.standardError])
		XCTAssertEqual(linesByFd[FileDescriptor.standardOutput, default: []].joined(), fileContents)
	}
	
	func testProcessLaunchAndStreamStdoutAndStderr() throws {
		struct ReadError : Error {}
		let scriptURL = URL(fileURLWithPath: #filePath)
			.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			.appendingPathComponent("TestsData").appendingPathComponent("scripts").appendingPathComponent("slow-and-interleaved-output.swift")
		
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
		
		XCTAssertEqual(linesByFd[FileDescriptor.standardOutput, default: []].joined(), expectedStdout)
		/* We do not check for equality here because swift sometimes log errors on
		 * stderr before launching the script… */
		XCTAssert(linesByFd[FileDescriptor.standardError, default: []].joined().hasSuffix(expectedStderr))
	}
	
	@available(macOS 10.15.4, *)
	func testNonStandardFdCapture() throws {
		struct ReadError : Error {}
		let scriptURL = URL(fileURLWithPath: #filePath)
			.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			.appendingPathComponent("TestsData").appendingPathComponent("scripts").appendingPathComponent("write-500-lines.swift")
		
		let n = 50
		
		let pipe = Pipe()
		let fdRead = pipe.fileHandleForReading.fileDescriptor
		let fdWrite = pipe.fileHandleForWriting.fileDescriptor
		
		var count = 0
		let (process, outputGroup) = try Process.spawnedAndStreamedProcess(
			scriptURL.path, args: ["\(n)", "\(fdWrite)"], stdin: nil,
			stdoutRedirect: .none, stderrRedirect: .none,
			fileDescriptorsToSend: [FileDescriptor(rawValue: fdWrite): FileDescriptor(rawValue: fdWrite)],
			additionalOutputFileDescriptors: [FileDescriptor(rawValue: fdRead)],
			signalsToForward: [],
			outputHandler: { line, fd in
				guard fd.rawValue != FileHandle.standardError.fileDescriptor else {
					/* When a Swift script is launched, swift can output some shit on
					 * stderr… */
					NSLog("%@", "Got err from script: \(line)")
					return
				}
				
				XCTAssertEqual(fd.rawValue, fdRead)
				XCTAssertEqual(line, "I will not leave books on the ground.\n")
				Thread.sleep(forTimeInterval: 0.05) /* Greater than wait time in script. */
				if count == 0 {
					Thread.sleep(forTimeInterval: 3)
				}
				
				count += 1
			}
		)
		
		try FileDescriptor(rawValue: fdWrite).close()
		process.waitUntilExit()
		
		XCTAssertLessThan(count, n)
		
		let r = outputGroup.wait(timeout: .now() + .seconds(7))
		XCTAssertEqual(r, .success)
		XCTAssertEqual(count, n)
	}
	
	/* This disabled test has allowed the discovery of a leak of fds: the reading
	 * ends of the pipes that are created when capturing the output of a process
	 * were not closed when the end of the streams were reached.
	 * The test is now disabled because it is excessively long.
	 *
	 * For reference the bug manifested in three ways that can still happen in
	 * case of starvation of file descriptors in the process, but that I don’t
	 * think I can detect and/or prevent (well I have a theory now for the two
	 * last cases, which might be detectable though; see the third case for
	 * explanation):
	 *    - The test crashes because of an ObjC exception: Process is not
	 *      launched. The exception is thrown when the `terminationStatus`
	 *      property is read inside the `spawnAndStream` method.
	 *    - The test simply stops forever. This is because the stream group never
	 *      reaches the end, and the `spawnAndStream` method simply waits forever
	 *      for the group to be over.
	 *    - More rare, but it happened, we can get an assertion failure inside
	 *      the `spawnedAndStreamedProcess` method, when adding the reading ends
	 *      of the pipes created in the output file descriptors variable. I think
	 *      this one might actually be the same of the previous one: the reading
	 *      end of the pipe would be an invalid fd. If both the pipe for stdout
	 *      and stderr have an invalid fd for their reading ends, we’d add the
	 *      same fd in the output fds twice, which is protected by an assert. In
	 *      the previous case, maybe the stream group never reaches the end
	 *      because the reading is done on an invalid fd which simply never
	 *      triggers a read.
	 *      This explanation is a theory. I could verify it, but it’s an edge
	 *      case and I don’t really feel like it for now. */
	func disabledTestLaunchProcessWithResourceStarving() throws {
		/* It has been observed that on my computer, things starts to go bad when
		 * there are roughly 6500 fds open.
		 * So we start by opening 6450 fds. */
		for _ in 0..<6450 {
			_ = try FileDescriptor.open("/dev/random", .readOnly)
		}
		for _ in 0..<5000 {
			let (exitCode, exitReason) = try Process.spawnAndStream(
				"/bin/sh", args: ["-c", "echo hello"],
				stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
				signalsToForward: [],
				outputHandler: { _, _ in }
			)
			guard exitCode == 0, exitReason == .exit else {
				struct UnexpectedExit : Error {}
				throw UnexpectedExit()
			}
		}
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

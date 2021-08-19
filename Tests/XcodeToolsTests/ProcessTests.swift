import Foundation
import XCTest

import CLTLogger
import Logging
import StreamReader
import SystemPackage

import Utils

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
	
	func testProcessSpawnWithWorkdirAndEnvChange() throws {
		let checkPwdAndEnvPath = Self.scriptsPath.appending("check-pwd+env.swift")
		
		let workingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)
		defer {_ = try? FileManager.default.removeItem(at: workingDirectory)}
		
		guard let realpathDir = realpath(workingDirectory.path, nil) else {
			struct CannotGetRealPath : Error {var sourcePath: String}
			throw CannotGetRealPath(sourcePath: workingDirectory.path)
		}
		let expectedWorkingDirectory = String(cString: realpathDir)
		
		let expectedEnvValue = UUID().uuidString
		
		let (exitCode, exitReason, outputs) = try Process.spawnAndGetOutput(checkPwdAndEnvPath, args: ["XCT_PROCESS_TEST_VALUE"], workingDirectory: workingDirectory, environment: ["XCT_PROCESS_TEST_VALUE": expectedEnvValue])
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(exitReason, .exit)
		XCTAssertEqual(outputs, [.standardOutput: expectedWorkingDirectory + "\n" + expectedEnvValue + "\n"])
	}
	
	func testProcessSpawnAndStreamStdin() throws {
		struct ReadError : Error {}
		let filePath = Self.filesPath.appending("three_lines.txt")
		let fd = try FileDescriptor.open(filePath, .readOnly)
		let fileContents = try fd.closeAfter{ () -> String in
			guard let r = try String(data: FileDescriptorReader(stream: fd, bufferSize: 256, bufferSizeIncrement: 128).readDataToEnd(), encoding: .utf8) else {
				throw ReadError()
			}
			return r
		}
		
		var linesByFd = [FileDescriptor: [String]]()
		let (terminationStatus, terminationReason) = try Process.spawnAndStream(
			"/bin/cat", args: [],
			stdin: FileDescriptor.open(filePath, .readOnly),
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
	
	func testProcessSpawnAndStreamStdoutAndStderr() throws {
		struct ReadError : Error {}
		let scriptURL = Self.scriptsPath.appending("slow-and-interleaved-output.swift")
		
		let n = 3 /* Not lower than 2 to get fdSwitchCount high enough */
		let t = 0.25
		
		var fdSwitchCount = 0
		var previousFd: FileDescriptor?
		var linesByFd = [FileDescriptor: [String]]()
		let (terminationStatus, terminationReason) = try Process.spawnAndStream(
			scriptURL, args: ["\(n)", "\(t)"], stdin: nil,
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
		let scriptURL = Self.scriptsPath.appending("write-500-lines.swift")
		
		let n = 50
		
		let pipe = Pipe()
		let fdRead = pipe.fileHandleForReading.fileDescriptor
		let fdWrite = pipe.fileHandleForWriting.fileDescriptor
		
		var count = 0
		let (process, outputGroup) = try Process.spawnedAndStreamedProcess(
			scriptURL, args: ["\(n)", "\(fdWrite)"], stdin: nil,
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
	 *      Apparently this is *not* due to fd starvation as I got this in a
	 *      normal run. It was highly likely to have been due to a leak in the
	 *      stream sources that were never cancelled when a Process failed to
	 *      launch. I never confirmed it because reproducibility was hard, but it
	 *      is very likely. See f499ac28b08fc9f4bb8611c34b40baebd1b12d03.
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
	 *      This explanation is a theory. I have actually verified that we get an
	 *      invalid Pipe object when initializing a Pipe when no more fds are
	 *      available, which did trigger the assertion failure, and now properly
	 *      detect this problem. See `testLaunchProcessWithResourceStarving` for
	 *      more info. For the rest of the cases, I’m not sure how to reproduce
	 *      them exactly. */
	func disabledTestSpawnProcessWithResourceStarving() throws {
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
	
	func testSpawnProcessWithResourceStarving() throws {
		/* Let’s starve the fds first */
		var fds = Set<FileDescriptor>()
		while let fd = try? FileDescriptor.open("/dev/random", .readOnly) {fds.insert(fd)}
		defer {fds.forEach{ try? $0.close() }}
		
		func releaseRandomFd() throws {
			guard let randomFd = fds.randomElement() else {
				throw XcodeToolsError.internalError("We starved the fds without opening a lot of files it seems.")
			}
			try randomFd.close()
			fds.remove(randomFd)
		}
		
		/* Now we try and use Process */
		XCTAssertThrowsError(try Process.spawnAndStream(
			"/bin/sh", args: ["-c", "echo hello"],
			stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
			signalsToForward: [],
			outputHandler: { _, _ in }
		))
		
		/* We release two fds. */
		try releaseRandomFd()
		try releaseRandomFd()
		/* Using process should still fail, but with error when opening Pipe for
		 * stderr, not stdout. To verify, the test would have to be modified, but
		 * the check would not be very stable, so we simply verify we still get a
		 * failure. */
		XCTAssertThrowsError(try Process.spawnAndStream(
			"/bin/sh", args: ["-c", "echo hello"],
			stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
			signalsToForward: [],
			outputHandler: { _, _ in }
		))
		
		/* Now let’s release more fds.
		 * If we release two, we get an error with a read from a bad fd. Not sure
		 * why, but it’s not very much surprising.
		 * If we release one more it seems to work. */
		try releaseRandomFd()
		try releaseRandomFd()
		try releaseRandomFd()
		let (exitCode, exitReason, outputs) = try Process.spawnAndGetOutput(
			"/bin/sh", args: ["-c", "echo hello"],
			stdin: nil, signalsToForward: []
		)
		XCTAssertEqual(exitCode, 0)
		XCTAssertEqual(exitReason, .exit)
		XCTAssertEqual(outputs, [.standardOutput: "hello\n"])
	}
	
	func testSpawnProcessWithNonExistentExecutable() throws {
		let inexistentScriptURL = Self.scriptsPath.appending("inexistent.swift")
		XCTAssertThrowsError(try Process.spawnAndGetOutput(inexistentScriptURL))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("__ inexistent __")) /* We hope nobody will ever create the "__ inexistent __" executable :-) */
	}
	
	func testPathSearch() throws {
		let scriptsPath = Self.scriptsPath
		
		let currentWD = FileManager.default.currentDirectoryPath
		defer {FileManager.default.changeCurrentDirectoryPath(currentWD)}
		
		XCTAssertThrowsError(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: nil, environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: .some(nil), environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: [""], environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("./check-pwd+env.swift", usePATH: true, customPATH: [scriptsPath], environment: [:]))
		XCTAssertNoThrow(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: [scriptsPath], environment: [:]))
		
		let curPath = getenv("PATH").flatMap{ String(cString: $0) }
		defer {
			if let curPath = curPath {setenv("PATH", curPath, 1)}
			else                     {unsetenv("PATH")}
		}
		let path = curPath ?? ""
		let newPath = path + (path.isEmpty ? "" : ":") + scriptsPath.string
		setenv("PATH", newPath, 1)
		
		XCTAssertThrowsError(try Process.spawnAndGetOutput("__ inexistent __", usePATH: true, environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: .some(nil), environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: [""], environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("./check-pwd+env.swift", usePATH: true, customPATH: nil, environment: [:]))
		XCTAssertThrowsError(try Process.spawnAndGetOutput("./check-pwd+env.swift", usePATH: false, environment: [:]))
		XCTAssertNoThrow(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: nil, environment: [:]))
		XCTAssertNoThrow(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, environment: [:]))
		
		FileManager.default.changeCurrentDirectoryPath(scriptsPath.string)
		XCTAssertNoThrow(try Process.spawnAndGetOutput("check-pwd+env.swift", usePATH: true, customPATH: [""], environment: [:]))
		XCTAssertNoThrow(try Process.spawnAndGetOutput("./check-pwd+env.swift", usePATH: true, customPATH: nil, environment: [:]))
		XCTAssertNoThrow(try Process.spawnAndGetOutput("./check-pwd+env.swift", usePATH: false, environment: [:]))
		/* Sadly the error we get is a file not found */
		XCTAssertThrowsError(try Process.spawnAndGetOutput("./not-executable.swift", usePATH: false, environment: [:]))
	}
	
	/* Disabled because long, but allowed me to find multiple memory leaks.
	 * Fully commented instead of just renamed disabled* because does not compile
	 * on Linux because of autoreleasepool. */
//	func disabledTestLotsOfRuns() throws {
//		try autoreleasepool{
//			for _ in 0..<50 {
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift")))
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift")))
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift")))
//				XCTAssertNoThrow(try Process.spawnAndGetOutput(Self.scriptsPath.appending("check-pwd+env.swift")))
//			}
//		}
//	}
	
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

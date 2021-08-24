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
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			let checkCwdAndEnvPath = Self.scriptsPath.appending("check-cwd+env.swift")
			
			let workingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
			try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)
			defer {_ = try? FileManager.default.removeItem(at: workingDirectory)}
			
			guard let realpathDir = realpath(workingDirectory.path, nil) else {
				struct CannotGetRealPath : Error {var sourcePath: String}
				throw CannotGetRealPath(sourcePath: workingDirectory.path)
			}
			let expectedWorkingDirectory = String(cString: realpathDir)
			
			let expectedEnvValue = UUID().uuidString
			
			let (exitCode, exitReason, outputs) = try await Process.spawnAndGetOutput(checkCwdAndEnvPath, args: ["XCT_PROCESS_TEST_VALUE"], workingDirectory: workingDirectory, environment: ["XCT_PROCESS_TEST_VALUE": expectedEnvValue], signalsToForward: [])
			XCTAssertEqual(exitCode, 0)
			XCTAssertEqual(exitReason, .exit)
			XCTAssertEqual(try textOutputFromOutputs(outputs), [.standardOutput: expectedWorkingDirectory + "\n" + expectedEnvValue + "\n"])
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testProcessSpawnAndStreamStdin() throws {
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			struct ReadError : Error {}
			for file in ["three-lines.txt", "big.txt"] {
				let filePath = Self.filesPath.appending(file)
				let fileContents = try String(contentsOf: filePath.url)
				
				let fd = try FileDescriptor.open(filePath, .readOnly)
				let (exitStatus, exitReason, outputs) = try await Process.spawnAndGetOutput("/bin/cat", stdin: fd, signalsToForward: [])
				try fd.close()
				
				XCTAssertEqual(exitStatus, 0)
				XCTAssertEqual(exitReason, .exit)
				
				XCTAssertNil(outputs[FileDescriptor.standardError])
				XCTAssertEqual(try textOutputFromOutputs(outputs)[FileDescriptor.standardOutput], fileContents)
			}
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testProcessSpawnAndStreamStdoutAndStderr() throws {
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			struct ReadError : Error {}
			let scriptURL = Self.scriptsPath.appending("slow-and-interleaved-output.swift")
			
			let n = 3 /* Not lower than 2 to get fdSwitchCount high enough */
			let t = 0.25
			
			var fdSwitchCount = 0
			var previousFd: FileDescriptor?
			var linesByFd = [FileDescriptor: [(Data, Data)]]()
			let (terminationStatus, terminationReason) = try await Process.spawnAndStream(
				scriptURL, args: ["\(n)", "\(t)"], stdin: nil,
				stdoutRedirect: .capture, stderrRedirect: .capture, signalsToForward: [],
				outputHandler: { line, sep, fd, _, _ in
					if previousFd != fd {
						fdSwitchCount += 1
						previousFd = fd
					}
					linesByFd[fd, default: []].append((line, sep))
				}
			)
			let textLinesByFd = try textOutputFromOutputs(linesByFd)
			
			XCTAssertGreaterThan(fdSwitchCount, 2)
			
			XCTAssertEqual(terminationStatus, 0)
			XCTAssertEqual(terminationReason, .exit)
			
			let expectedStdout = (1...n).map{ String(repeating: "*", count: $0)           }.joined(separator: "\n") + "\n"
			let expectedStderr = (1...n).map{ String(repeating: "*", count: (n - $0 + 1)) }.joined(separator: "\n") + "\n"
			
			XCTAssertEqual(textLinesByFd[FileDescriptor.standardOutput] ?? "", expectedStdout)
			/* We do not check for equality here because swift sometimes log errors on
			 * stderr before launching the script… */
			XCTAssertTrue((textLinesByFd[FileDescriptor.standardError] ?? "").hasSuffix(expectedStderr))
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testProcessTerminationHandler() throws {
		var wentIn = false
		let g = DispatchGroup()
		let p = try Process.spawnedAndStreamedProcess("/bin/cat", stdin: nil, signalsToForward: [], outputHandler: { _,_,_,_,_ in }, terminationHandler: { t in
			wentIn = true
		}, ioDispatchGroup: g)
		
		p.waitUntilExit()
		g.wait()
		
		XCTAssertTrue(wentIn)
	}
	
	func testNonStandardFdCapture() throws {
		let scriptURL = Self.scriptsPath.appending("write-500-lines.swift")
		
		let n = 50
		
		/* Do **NOT** use a `Pipe` object! (Or dup the fds you get from it). Pipe
		 * closes both ends of the pipe on dealloc, but we need to close one at a
		 * specific time and leave the other open (it is closed by the spawn
		 * function). */
		let (fdRead, fdWrite) = try Process.unownedPipe()
		
		var count = 0
		let outputGroup = DispatchGroup()
		let process = try Process.spawnedAndStreamedProcess(
			scriptURL, args: ["\(n)", "\(fdWrite.rawValue)"], stdin: nil,
			stdoutRedirect: .none, stderrRedirect: .none,
			fileDescriptorsToSend: [fdWrite: fdWrite],
			additionalOutputFileDescriptors: [fdRead],
			signalsToForward: [],
			outputHandler: { line, separator, fd, _, _ in
				guard fd != FileDescriptor.standardError else {
					/* When a Swift script is launched, swift can output some shit on
					 * stderr… */
					NSLog("%@", "Got err from script: \(line)")
					return
				}
				
				XCTAssertEqual(fd, fdRead)
				XCTAssertEqual(line, Data("I will not leave books on the ground.".utf8))
				XCTAssertEqual(separator, Data("\n".utf8))
				Thread.sleep(forTimeInterval: 0.05) /* Greater than wait time in script. */
				if count == 0 {
					Thread.sleep(forTimeInterval: 3)
				}
				
				count += 1
			},
			ioDispatchGroup: outputGroup
		)
		
		try fdWrite.close()
		process.waitUntilExit()
		
		XCTAssertLessThan(count, n)
		
		let r = outputGroup.wait(timeout: .now() + .seconds(7))
		XCTAssertEqual(r, .success)
		XCTAssertEqual(count, n)
	}
	
	/* This disabled (disabled because too long) test and some variants of it
	 * have allowed the discovery of some bugs:
	 *    - Leaks of file descriptors;
	 *    - Pipe fails to allocate new fds, but Pipe object init is non-fallible
	 *      in Swift… so we check either way (now we do not use the Pipe object
	 *      anyway, we get more control over the lifecycle of the fds);
	 *    - Race between executable end and io group, leading to potentially
	 *      closed fds _while setting up a new run_, leading to a lot of weird
	 *      behaviour, such as `process not launched exception`, assertion
	 *      failures in the spawn and stream method (same fd added twice in a
	 *      set, which is not possible), dead-lock with the io group being waited
	 *      on forever, partial data being read, etc.;
	 *    - Some fds were not closed at the proper location (this was more likely
	 *      discovered through `testNonStandardFdCapture`, but this one helped
	 *      too IIRC). */
	func disabledTestSpawnProcessWithResourceStarvingFirstDraft() throws {
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			
			/* It has been observed that on my computer, things starts to go bad when
			 * there are roughly 6500 fds open.
			 * So we start by opening 6450 fds. */
			for _ in 0..<6450 {
				_ = try FileDescriptor.open("/dev/random", .readOnly)
			}
			for i in 0..<5000 {
				NSLog("%@", "***** NEW RUN: \(i+1) *****")
				let outputs = try await Process.checkedSpawnAndGetOutput("/bin/sh", args: ["-c", "echo hello"], signalsToForward: [])
				XCTAssertEqual(try textOutputFromOutputs(outputs), [FileDescriptor.standardOutput: "hello\n"])
			}
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testSpawnProcessWithResourceStarving() throws {
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			
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
			await tempAsyncAssertThrowsError(try await Process.spawnAndStream(
				"/bin/sh", args: ["-c", "echo hello"],
				stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
				signalsToForward: [],
				outputHandler: { _,_,_,_,_ in }
			))
			
			/* We release two fds. */
			try releaseRandomFd()
			try releaseRandomFd()
			/* Using process should still fail, but with error when opening Pipe for
			 * stderr, not stdout. To verify, the test would have to be modified, but
			 * the check would not be very stable, so we simply verify we still get a
			 * failure. */
			await tempAsyncAssertThrowsError(try await Process.spawnAndStream(
				"/bin/sh", args: ["-c", "echo hello"],
				stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
				signalsToForward: [],
				outputHandler: { _,_,_,_,_ in }
			))
			
			/* Now let’s release more fds.
			 * If we release three, we get an error with a read from a bad fd. Not
			 * sure why, but it’s not very much surprising.
			 * If we release one more it seems to work. */
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
#if os(Linux)
			/* Apparently Linux uses more fds to launch a subprocess. */
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
			try releaseRandomFd()
#endif
			let (exitCode, exitReason, outputs) = try await Process.spawnAndGetOutput(
				"/bin/sh", args: ["-c", "echo hello"],
				stdin: nil, signalsToForward: []
			)
			XCTAssertEqual(exitCode, 0)
			XCTAssertEqual(exitReason, .exit)
			XCTAssertEqual(try textOutputFromOutputs(outputs), [.standardOutput: "hello\n"])
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	func testPathSearch() throws {
		/* LINUXASYNC START --------- */
		let group = DispatchGroup()
		group.enter()
		Task{
			/* LINUXASYNC STOP --------- */
			
			let spyScriptPath = FilePath("spy.swift")
			let nonexistentScriptPath = FilePath(" this-file-does-not-and-must-not-exist.txt ") /* We hope nobody will create an executable with this name in the PATH */
			
			let notExecutableScriptComponent = FilePath.Component("not-executable.swift")
			let notExecutablePathInCwd = FilePath(root: nil, components: ".", notExecutableScriptComponent)
			
			let checkCwdAndEnvScriptComponent = FilePath.Component("check-cwd+env.swift")
			let checkCwdAndEnvPath      = FilePath(root: nil, components:      checkCwdAndEnvScriptComponent)
			let checkCwdAndEnvPathInCwd = FilePath(root: nil, components: ".", checkCwdAndEnvScriptComponent)
			
			let currentWD = FileManager.default.currentDirectoryPath
			defer {FileManager.default.changeCurrentDirectoryPath(currentWD)}
			
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(nonexistentScriptPath, signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: nil, signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: .some(nil), signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: [""], signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPathInCwd, usePATH: true, customPATH: [Self.scriptsPath], signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: [Self.scriptsPath], signalsToForward: []))
			
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(spyScriptPath, usePATH: false,                                                 signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(spyScriptPath, usePATH: true,  customPATH: [Self.filesPath],                   signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(spyScriptPath,     usePATH: true,  customPATH: [Self.scriptsPath],                 signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(spyScriptPath,     usePATH: true,  customPATH: [Self.scriptsPath, Self.filesPath], signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(spyScriptPath,     usePATH: true,  customPATH: [Self.filesPath, Self.scriptsPath], signalsToForward: []))
			
			let curPath = getenv("PATH").flatMap{ String(cString: $0) }
			defer {
				if let curPath = curPath {setenv("PATH", curPath, 1)}
				else                     {unsetenv("PATH")}
			}
			let path = curPath ?? ""
			let newPath = path + (path.isEmpty ? "" : ":") + Self.scriptsPath.string
			setenv("PATH", newPath, 1)
			
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(nonexistentScriptPath, usePATH: true, signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: .some(nil), signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: [""], signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPathInCwd, usePATH: true, customPATH: nil, signalsToForward: []))
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(checkCwdAndEnvPathInCwd, usePATH: false, signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: nil, signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, signalsToForward: []))
			
			FileManager.default.changeCurrentDirectoryPath(Self.scriptsPath.string)
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPath, usePATH: true, customPATH: [""], signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPathInCwd, usePATH: true, customPATH: nil, signalsToForward: []))
			await tempAsyncAssertNoThrow(try await Process.spawnAndGetOutput(checkCwdAndEnvPathInCwd, usePATH: false, signalsToForward: []))
			/* Sadly the error we get is a file not found */
			FileManager.default.changeCurrentDirectoryPath(Self.filesPath.string)
			await tempAsyncAssertThrowsError(try await Process.spawnAndGetOutput(notExecutablePathInCwd, usePATH: false, signalsToForward: []))
			
			/* LINUXASYNC START --------- */
			group.leave()
		}
		group.wait()
		/* LINUXASYNC STOP --------- */
	}
	
	/* Disabled because long, but allowed me to find multiple memory leaks.
	 * Fully commented instead of just renamed disabled* because does not compile
	 * on Linux because of autoreleasepool. */
//	func disabledTestLotsOfRuns() throws {
//		try autoreleasepool{
//			for _ in 0..<50 {
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift"), signalsToForward: []))
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift"), signalsToForward: []))
//				XCTAssertThrowsError(try Process.spawnAndGetOutput(Self.scriptsPath.appending("not-executable.swift"), signalsToForward: []))
//				XCTAssertNoThrow(try Process.spawnAndGetOutput(Self.scriptsPath.appending(checkCwdAndEnvPath), signalsToForward: []))
//			}
//		}
//	}
	
	/* While XCTest does not have support for async for XCTAssertThrowsError */
	private func tempAsyncAssertThrowsError<T>(_ block: @autoclosure () async throws -> T, _ message: @escaping @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (_ error: Error) -> Void = { _ in }) async {
		do    {_ = try await block(); XCTAssertThrowsError(    {             }(), message(), file: file, line: line, errorHandler)}
		catch {                       XCTAssertThrowsError(try { throw error }(), message(), file: file, line: line, errorHandler)}
	}
	
	/* While XCTest does not have support for async for XCTAssertNoThrow */
	private func tempAsyncAssertNoThrow<T>(_ block: @autoclosure () async throws -> T, _ message: @escaping @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line, _ errorHandler: (_ error: Error) -> Void = { _ in }) async {
		do    {_ = try await block(); XCTAssertNoThrow(    {             }(), message(), file: file, line: line)}
		catch {                       XCTAssertNoThrow(try { throw error }(), message(), file: file, line: line)}
	}
	
	private func textOutputFromOutputs(_ outputs: [FileDescriptor: [(Data, Data)]]) throws -> [FileDescriptor: String] {
		struct InvalidLine : Error {var hexLine: String}
		struct InvalidSeparator : Error {var hexSep: String}
		return try outputs.mapValues{
			try $0.reduce("", { current, lineAndSep in
				guard let line = String(data: lineAndSep.0, encoding: .utf8) else {
					throw InvalidLine(hexLine: lineAndSep.0.reduce("", { $0 + String(format: "%02x", $1) }))
				}
				guard let sep = String(data: lineAndSep.1, encoding: .utf8) else {
					throw InvalidLine(hexLine: lineAndSep.1.reduce("", { $0 + String(format: "%02x", $1) }))
				}
				return current + line + sep
			})
		}
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

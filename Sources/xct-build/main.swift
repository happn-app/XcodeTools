import Foundation

import ArgumentParser
import CLTLogger
import Logging
import StreamReader
import SystemPackage

import libxct



/* Big up to https://github.com/jjrscott/XcodeBuildResultStream */
struct XctBuild : ParsableCommand {
	
	static let execPathEnvVarName = "XCT_EXEC_PATH"
	
	static var configuration = CommandConfiguration(
		abstract: "Build an Xcode project",
		discussion: "Hopefully, the options supported by this tool are easier to understand than xcodebuild’s."
	)
	
	static var logger: Logger = {
		var ret = Logger(label: "main")
		ret.logLevel = .debug
		return ret
	}()
	
	@Option
	var xcodebuildPath: String = "/usr/bin/xcodebuild"
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
//		LibXctConfig.logger?.logLevel = .trace
		XctBuild.logger.logLevel = .trace
		
		let pipe = Pipe()
		let fhXcodeReadOutput = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
		let fhXcodeWriteOutput = FileDescriptor(rawValue: pipe.fileHandleForWriting.fileDescriptor)
		let resultBundlePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("xcresult").path
		/* TODO: When SystemPackage is updated, use FilePath (not interesting to
		 * use in version 0.0.1) */
		let resultStreamPath = "/dev/fd/\(fhXcodeWriteOutput.rawValue)"
		
		let args = [
			"-scheme", "GPS Stone",
			"-resultBundlePath", resultBundlePath,
			"-resultStreamPath", resultStreamPath
		]
		let (terminationStatus, terminationReason) = try Process.spawnAndStream(
			"/usr/bin/xcodebuild", args: args,
			stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
			fileDescriptorsToSend: [fhXcodeWriteOutput: fhXcodeWriteOutput],
			additionalOutputFileDescriptors: [fhXcodeReadOutput],
			outputHandler: { line, fd in
				guard fd == fhXcodeReadOutput else {return}
				var line = line
				if line.last == "\n" {line.removeLast()}
				XctBuild.logger.trace("\(line)")
			}
		)
		XctBuild.logger.trace("termination: \(terminationStatus), \(terminationReason.rawValue)")
	}
	
}

XctBuild.main()

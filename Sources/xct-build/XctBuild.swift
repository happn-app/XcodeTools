import Foundation

import ArgumentParser
import CLTLogger
import Logging
import StreamReader
import SystemPackage

import XcodeJsonOutput
import XcodeTools



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
	
	/* TODO: For now only one scheme only. Later multiple schemes? */
	@Option
	var scheme: String
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger() }
//		XcodeToolsConfig.logger?.logLevel = .trace
		XctBuild.logger.logLevel = .trace
		
		let pipe = Pipe()
		let fhXcodeReadOutput = FileDescriptor(rawValue: pipe.fileHandleForReading.fileDescriptor)
		let fhXcodeWriteOutput = FileDescriptor(rawValue: pipe.fileHandleForWriting.fileDescriptor)
		
		guard let outputFdComponent = FilePath.Component(String(fhXcodeWriteOutput.rawValue)) else {
			/* TODO: Error */
			throw NSError(domain: "yo", code: 1, userInfo: nil)
		}
		
		let resultBundlePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("xcresult").path
		let resultStreamPath: FilePath = FilePath(root: "/", components: "dev", "fd", outputFdComponent)
		
		let args = [
			"-verbose",// "-json",
			"-disableAutomaticPackageResolution",
			"-scheme", scheme,
			"-resultBundlePath", resultBundlePath,
			"-resultStreamPath", resultStreamPath.string,
			"test"
		]
		let (process, outputGroup) = try Process.spawnedAndStreamedProcess(
			"/usr/bin/xcodebuild", args: args,
			stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
			fileDescriptorsToSend: [fhXcodeWriteOutput: fhXcodeWriteOutput],
			additionalOutputFileDescriptors: [fhXcodeReadOutput],
			outputHandler: { line, fd in
				var line = line
				if line.last == "\n" {line.removeLast()}
				switch fd {
					case fhXcodeReadOutput:
//						XctBuild.logger.trace("json: \(line)")
						do {
							guard let streamedEvent = try Parser.parse(jsonString: line) as? StreamedEvent else {
								/* TODO: Error */
								throw NSError(domain: "yo", code: 1, userInfo: nil)
							}
							if let readable = streamedEvent.structuredPayload.humanReadableEvent(withColors: false) {
								print(readable)
							} else {
//								XctBuild.logger.trace("skipped streamed event w/ no human readable description: \(streamedEvent)")
							}
						} catch {
							XctBuild.logger.error("\(error)")
						}
						
					case FileDescriptor.standardOutput: ()//XctBuild.logger.trace("stdout: \(line)")
					case FileDescriptor.standardError:  ()//XctBuild.logger.trace("stderr: \(line)")
					default:                            XctBuild.logger.trace("unknown 😱: \(line)")
				}
			}
		)
		/* TODO: spawnedAndStreamedProcess should close the file descriptor to
		 *       send, maybe w/ an option not to. For now we close it manually. */
		try fhXcodeWriteOutput.close()
		process.waitUntilExit()
		outputGroup.wait()
		XctBuild.logger.trace("termination: \(process.terminationStatus), \(process.terminationReason.rawValue)")
	}
	
}

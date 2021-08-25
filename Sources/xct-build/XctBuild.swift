import Foundation

import ArgumentParser
import CLTLogger
import Logging
import StreamReader
import SystemPackage

import XcodeJsonOutput
import XcodeTools



/* Big up to https://github.com/jjrscott/XcodeBuildResultStream */
@main
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
		
		let (fdXcodeReadOutput, fdXcodeWriteOutput) = try Process.unownedPipe()
		guard let outputFdComponent = FilePath.Component(String(fdXcodeWriteOutput.rawValue)) else {
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
			"-resultStreamPath", resultStreamPath.string
		]
		let outputGroup = DispatchGroup()
		let process = try Process.spawnedAndStreamedProcess(
			"/usr/bin/xcodebuild", args: args,
			stdin: nil, stdoutRedirect: .capture, stderrRedirect: .capture,
			fileDescriptorsToSend: [fdXcodeWriteOutput: fdXcodeWriteOutput],
			additionalOutputFileDescriptors: [fdXcodeReadOutput],
			outputHandler: { lineResult, _, _ in
				do {
					let strLineWithSource = try lineResult.get().lineWithSource
					switch strLineWithSource.fd {
						case fdXcodeReadOutput:
//							XctBuild.logger.trace("json: \(strLineWithSource.line)")
							guard let streamedEvent = try Parser.parse(jsonString: strLineWithSource.line) as? StreamedEvent else {
								/* TODO: Error */
								throw NSError(domain: "yo", code: 1, userInfo: nil)
							}
							if let readable = streamedEvent.structuredPayload.humanReadableEvent(withColors: false) {
								print(readable)
							} else {
//								XctBuild.logger.trace("skipped streamed event w/ no human readable description: \(streamedEvent)")
							}
							
						case FileDescriptor.standardOutput: ()//XctBuild.logger.trace("stdout: \(strLineWithSource.line)")
						case FileDescriptor.standardError:  ()//XctBuild.logger.trace("stderr: \(strLineWithSource.line)")
						default:                            XctBuild.logger.error("line from unknown fd: \(strLineWithSource)")
					}
				} catch {
					XctBuild.logger.trace("error processing output line from xcodebuild: \(error)")
				}
			},
			ioDispatchGroup: outputGroup
		)
		/* TODO: Maybe spawnedAndStreamedProcess should close the file descriptor to send, maybe w/ an option not to. For now we close it manually. */
		try fdXcodeWriteOutput.close()
		process.waitUntilExit()
		outputGroup.wait()
		XctBuild.logger.trace("termination: \(process.terminationStatus), \(process.terminationReason.rawValue)")
	}
	
}

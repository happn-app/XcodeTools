import Foundation

import ArgumentParser
import CLTLogger
import Logging
import SystemPackage



/* Big up to https://github.com/jjrscott/XcodeBuildResultStream */
struct XctBuild : ParsableCommand {
	
	static let execPathEnvVarName = "XCT_EXEC_PATH"
	
	static var configuration = CommandConfiguration(
		abstract: "Build an Xcode project",
		discussion: "Hopefully, the options supported by this tool are easier to understand than xcodebuild’s."
	)
	
	static var logger: Logger = {
		LoggingSystem.bootstrap{ _ in CLTLogger(messageTerminator: "\n") }
		return Logger(label: "main")
	}()
	
	@Option
	var xcodebuildPath: String = "/usr/bin/xcodebuild"
	
	func run() throws {
		guard let execBaseURL = getenv(XctBuild.execPathEnvVarName).flatMap({ URL(fileURLWithPath: String(cString: $0)) }) else {
			XctBuild.logger.error("Expected XCT_EXEC_PATH to be set! If you ran xct-build manually (instead of using \"xct build\"), please set it.")
			/* TODO: Use an actual error */
			throw Errno(rawValue: 1)
		}
		
		let pipe = Pipe()
		let resultBundlePath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("xcresult").path
		/* When SystemPackage is updated, use FilePath (not interesting to use in
		 * version 0.0.1) */
		let resultStreamPath = URL(fileURLWithPath: "/dev/fd").appendingPathComponent(String(pipe.fileHandleForWriting.fileDescriptor)).path
		
		/* We want to launch xcodebuild, but w/ more than just stdin, stdout and
		 * stderr correctly dup’d (which Process does correctly); we also need to
		 * dup pipe.fileHandleForWriting.fileDescriptor (presumably via
		 * posix_spawn_file_actions_adddup2 or such), but Process does not let us
		 * do that!
		 * So instead we launch an internal launcher, which will wait until it
		 * receives the fd via a recvmsg(), which will make it valid inside the
		 * child process (IIUC; see https://stackoverflow.com/a/28005250 for more
		 * info about this).
		 * Another solution (maybe simpler, maybe not) would have been to re-write
		 * the setup done by Process and manually call posix_spawn. The source
		 * code of the Process class is here: https://github.com/apple/swift-corelibs-foundation/blob/main/Sources/Foundation/Process.swift */
		let xcodebuildProcess = Process()
		xcodebuildProcess.executableURL = execBaseURL.appendingPathComponent("xct")
		xcodebuildProcess.arguments = [
			"internal-fd-get-launcher", "/usr/bin/xcodebuild",
			"-resultBundlePath", resultBundlePath,
			"-resultStreamPath", resultStreamPath
		]
		
		try xcodebuildProcess.run()
		xcodebuildProcess.waitUntilExit()
	}
	
}

XctBuild.main()

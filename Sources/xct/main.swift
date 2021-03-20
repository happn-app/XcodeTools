import Foundation

import ArgumentParser
import CLTLogger
import Logging
import SystemPackage



// Might be useful some day: https://stackoverflow.com/a/26973384

struct Xct : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Xcode Tools – Manage, build, sign and deploy your Xcode projects.",
		discussion: "xct is a simple launcher for other XcodeTools binaries (xct-*). For instance, instead of calling “xct-versions”, you can call “xct versions”."
	)
	
	@Option(help: "Set the path to the core xct programs.")
	var execPath: String = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
	
	@Option(name: .customShort("C"), help: ArgumentHelp("Change working directory before calling the tool.", valueName: "path"))
	var workdir: String?
	
	@Argument
	var toolName: String
	
	@Argument(parsing: .unconditionalRemaining)
	var toolArguments: [String] = []
	
	func run() throws {
		LoggingSystem.bootstrap{ _ in CLTLogger(messageTerminator: "\n") }
		let logger = Logger(label: "main")
		
		/* Change current working if asked */
		if let workdir = workdir {
			guard FileManager.default.changeCurrentDirectoryPath(workdir) else {
				logger.error("Cannot set current directory to \(workdir)")
				throw ExitCode(1)
			}
		}
		
		/* Adding exec path to PATH */
		let path = getenv("PATH").flatMap{ String(cString: $0) } ?? ""
		let newPath = execPath + (path.isEmpty ? "" : ":") + path
		guard setenv("PATH", newPath, 1) == 0 else {
			logger.error("Error modifying PATH: \(Errno(rawValue: errno).description)")
			throw ExitCode(errno)
		}
		
		let fullToolName = "xct-" + toolName
		try withCStrings([fullToolName] + toolArguments, scoped: { cargs in
			/* The p implementation of exec searches for the binary path in PATH.
			 * The v means we pass an array to exec (as opposed to the variadic
			 * exec variant, which is not available in Swift anyway). */
			let ret = execvp(fullToolName, cargs)
			assert(ret != 0, "exec should not return if it was successful.")
			logger.error("Error running executable \(fullToolName): \(Errno(rawValue: errno).description)")
			throw ExitCode(errno)
		})
	}
	
	/* From https://gist.github.com/dduan/d4e967f3fc2801d3736b726cd34446bc */
	private func withCStrings(_ strings: [String], scoped: ([UnsafeMutablePointer<CChar>?]) throws -> Void) rethrows {
		let cStrings = strings.map{ strdup($0) }
		try scoped(cStrings + [nil])
		cStrings.forEach{ free($0) }
	}
	
}


Xct.main()

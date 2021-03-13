import Foundation

import ArgumentParser



// Might be useful some day: https://stackoverflow.com/a/26973384

struct Xct : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Xcode Tools – Manage, build, sign and deploy your Xcode projects.",
		discussion: "xct is a simple launcher for other XcodeTools binaries (xct-*). For instance, instead of calling “xct-versions”, you can call “xct versions”."
	)
	
	@Option(name: .customShort("C"), help: "Change working directory before calling the tool.")
	var pathToXcodeproj: String?
	
	@Argument
	var toolName: String
	
	@Argument
	var toolArguments: [String] = []
	
	func run() throws {
		let fullToolName = "xct-" + toolName
		try withCStrings([fullToolName], scoped: { cargs in
			/* The p implementation of exec searches for the binary path in PATH.
			 * The v means we pass an array to exec (as opposed to the variadic
			 * exec variant, which is not available in Swift anyway). */
			let ret = execvp(fullToolName, cargs)
			assert(ret != 0, "exec should not return if it was successful.")
			perror("Error running executable \(fullToolName)")
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

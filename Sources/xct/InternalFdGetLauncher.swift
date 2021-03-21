import Foundation

import ArgumentParser
import SystemPackage



struct InternalFdGetLauncher : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Internal launcher for xct which receives a fd before launching the tool."
	)
	
	@Argument
	var toolName: String
	
	@Argument(parsing: .unconditionalRemaining)
	var toolArguments: [String] = []
	
	func run() throws {
		try withCStrings([toolName] + toolArguments, scoped: { cargs in
			/* The v means we pass an array to exec (as opposed to the variadic
			 * exec variant, which is not available in Swift anyway). */
			let ret = execv(toolName, cargs)
			assert(ret != 0, "exec should not return if it was successful.")
			Xct.logger.error("Error running executable \(toolName): \(Errno(rawValue: errno).description)")
			throw ExitCode(errno)
		})
		
		fatalError("Unreachable code reached")
	}
	
}

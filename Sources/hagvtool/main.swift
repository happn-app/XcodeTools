import Foundation

import ArgumentParser



struct Hagvtool : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Deprecated. This tool is now a part of xct. You can use it by running \"xct versions\"."
	)
	
	@Argument
	var arguments: [String] = []
	
	func run() throws {
		#warning("Print message below to stderr instead of stdout.")
		print("⚠️ hagvtool has been deprecated. Please use \"xct versions\" instead.\n---------")
		try withCStrings(["xct-versions"] + arguments, scoped: { cargs in
			/* The p implementation of exec searches for the binary path in PATH.
			 * The v means we pass an array to exec (as opposed to the variadic
			 * exec variant, which is not available in Swift anyway). */
			let ret = execvP("xct-versions", URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path, cargs)
			assert(ret != 0, "exec should not return if it was successful.")
			perror("Error running executable xct-versions")
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


Hagvtool.main()

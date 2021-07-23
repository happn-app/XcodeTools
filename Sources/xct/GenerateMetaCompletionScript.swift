import Foundation

import ArgumentParser



/* This is the completion script for xct. We call it meta because it’s able to
 * call the sub-completion scripts for sub-commands properly. */
struct GenerateMetaCompletionScript : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Generate the completion script for xct. We use another algorithm than ArgumentParser’s, but I did not find a way to override the completion script from ArgumentParser, so I create a new command."
	)
	
	enum Shell : String, CaseIterable, ExpressibleByArgument {
		
		case zsh
		case bash
		
	}
	
	@Argument
	var shellName = Shell.zsh
	
	func run() throws {
		print("yellow for \(shellName)")
	}
	
}

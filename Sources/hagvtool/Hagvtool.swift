import Foundation

import ArgumentParser
import XcodeProjKit



struct Hagvtool : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Manage versions of Xcode projects",
		discussion: "This tool expects a specific setup of the Xcode projects in regard to the versioning (pretty much the only sane choice nowadays) and has a sub-command to validate said setup is correctly done.",
		subcommands: [
			ValidateVersionSetup.self
		]
	)
	
	struct Options : ParsableArguments {
		
		@Option
		var pathToXcodeproj: String?
		
	}
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
}

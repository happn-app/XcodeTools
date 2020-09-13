import Foundation

import ArgumentParser

import libhagvtool



struct Hagvtool : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Manage versions of Xcode projects",
		discussion: "This tool expects a specific setup of the Xcode projects in regard to the versioning (pretty much the only sane choice nowadays) and has a sub-command to validate said setup is correctly done.",
		subcommands: [
			GetBuildVersions.self,
			ValidateVersionSetup.self
		]
	)
	
	struct Options : ParsableArguments {
		
		@Option
		var pathToXcodeproj: String?
		
		@Option
		var targets = [String]()
		
		@Option
		var configurationNames = [String]()
		
		func targetMatches(_ targetName: String) -> Bool {
			guard !targets.isEmpty else {return true}
			return targets.contains(targetName)
		}
		
		func configurationNameMatches(_ configurationName: String) -> Bool {
			guard !configurationNames.isEmpty else {return true}
			return configurationNames.contains(configurationName)
		}
		
	}
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
}

import Foundation

import ArgumentParser

import libhagvtool



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		print(xcodeproj.pbxproj.rootObject.targets)
	}
	
}

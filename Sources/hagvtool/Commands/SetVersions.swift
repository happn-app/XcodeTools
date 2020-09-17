import Foundation

import ArgumentParser
import XcodeProjKit



struct SetVersions : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		print(try xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName))
	}
	
}

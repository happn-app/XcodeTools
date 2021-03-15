import Foundation

import ArgumentParser
import XcodeProjKit



struct SetBuildVersion : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	@OptionGroup
	var setVersionOptions: SetVersion.Options
	
	@Argument
	var newVersion: String
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		do {
			try SetVersion.setVersion(
				options: setVersionOptions, generalOptions: hagvtoolOptions,
				newVersion: newVersion,
				xcodeproj: xcodeproj,
				plistKey: "CFBundleVersion",
				buildSettingKey: "CURRENT_PROJECT_VERSION"
			)
		} catch {
			NSLog("%@", "There was an error setting the version of the project. Some files might have been modified.")
			throw error
		}
	}
	
}

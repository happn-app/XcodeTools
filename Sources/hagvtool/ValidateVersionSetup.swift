import Foundation

import ArgumentParser

import libhagvtool



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		try xcodeproj.managedObjectContext.performAndWait{
			try print(VersionSettings.allVersionSettings(project: xcodeproj.pbxproj.rootObject, xcodeprojURL: xcodeproj.xcodeprojURL))
//			guard let targets = xcodeproj.pbxproj.rootObject.targets else {
//				throw HagvtoolError(message: "Did not find any target in the project")
//			}
//			for target in targets {
//				guard let buildConfigurations = target.buildConfigurationList?.buildConfigurations else {
//					throw HagvtoolError(message: "Did not get the build configuration list (or the to-many relationship in it to the build configurations) in target \(target.name ?? "<unknown>")")
//				}
//				for buildConfiguration in buildConfigurations {
//
//					print(buildConfiguration)
//				}
//			}
		}
	}
	
}

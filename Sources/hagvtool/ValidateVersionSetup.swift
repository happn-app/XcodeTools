import Foundation

import ArgumentParser

import libhagvtool



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		xcodeproj.managedObjectContext.performAndWait{
//			print(xcodeproj.pbxproj.rootObject.targets?.flatMap{ ($0 as? PBXNativeTarget)?.buildConfigurationList?.buildConfigurations?.map{ $0 } })
		}
	}
	
}

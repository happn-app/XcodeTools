import Foundation

import XcodeProjKit



extension XcodeProj {
	
	func iterateCombinedBuildSettingsOfTargets(matchingOptions: Hagvtool.Options, _ handler: (_ target: PBXTarget, _ targetName: String, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> Void) throws {
		try iterateCombinedBuildSettingsOfTargets{ target, targetName, configurationName, combinedBuildSettings in
			guard matchingOptions.targetMatches(targetName) && matchingOptions.configurationNameMatches(configurationName) else {
				return
			}
			try handler(target, targetName, configurationName, combinedBuildSettings)
		}
	}
	
}

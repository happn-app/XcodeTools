import Foundation

import XcodeProj



extension XcodeProj {
	
	@discardableResult
	func iterateCombinedBuildSettingsOfTargets<T>(matchingOptions: XctVersions.Options, _ handler: (_ target: PBXTarget, _ targetName: String, _ configuration: XCBuildConfiguration, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> T) throws -> [T] {
		return try iterateCombinedBuildSettingsOfTargets{ target, targetName, configuration, configurationName, combinedBuildSettings in
			guard matchingOptions.targetMatches(targetName) && matchingOptions.configurationNameMatches(configurationName) else {
				return nil
			}
			return try handler(target, targetName, configuration, configurationName, combinedBuildSettings)
		}.compactMap{ $0 }
	}
	
}

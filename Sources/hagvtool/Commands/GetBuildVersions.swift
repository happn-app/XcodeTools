import Foundation

import ArgumentParser
import XcodeProjKit



struct GetBuildVersions : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	@Option
	var failOnMultipleVersions = false
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configurationName, combinedBuildSettings in
			print(#"[\#(targetName.bracketEscaped())][\#(configurationName.bracketEscaped())] = "\#(combinedBuildSettings["CURRENT_PROJECT_VERSION"])""#)
			if let plist = try combinedBuildSettings.infoPlistResolved(xcodeprojURL: xcodeproj.xcodeprojURL) {
				print(#"[\#(targetName.bracketEscaped())][\#(configurationName.bracketEscaped())][plist] = "\#(plist["CFBundleVersion"] ?? "")""#)
			}
		}
	}
	
}

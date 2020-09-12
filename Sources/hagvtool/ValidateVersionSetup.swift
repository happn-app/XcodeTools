import Foundation

import ArgumentParser

import libhagvtool



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		try xcodeproj.managedObjectContext.performAndWait{
			let combinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: xcodeproj.pbxproj.rootObject, xcodeprojURL: xcodeproj.xcodeprojURL)
			print(combinedBuildSettings.keys)
			print(combinedBuildSettings.mapValues{ $0.keys })
			try print(combinedBuildSettings["happn"]?["Release"]?[BuildSettingKey(serializedKey: "VERSIONING_SYSTEM")] ?? "<nil>")
//			versioningSystem = try rawBuildSettings.getIfExists("VERSIONING_SYSTEM")
//			currentProjectVersion = try rawBuildSettings.getIfExists("CURRENT_PROJECT_VERSION")
//			currentLibraryVersion = try rawBuildSettings.getIfExists("DYLIB_CURRENT_VERSION")
//			compatibilityLibraryVersion = try rawBuildSettings.getIfExists("DYLIB_COMPATIBILITY_VERSION")
//			marketingVersion = try rawBuildSettings.getIfExists("MARKETING_VERSION")
//			infoPlistPath = try rawBuildSettings.getIfExists("INFOPLIST_FILE")
//			versionInfoBuilder = try rawBuildSettings.getIfExists("VERSION_INFO_BUILDER")
//			versionInfoExportDeclaration = try rawBuildSettings.getIfExists("VERSION_INFO_EXPORT_DECL")
//			versionInfoFile = try rawBuildSettings.getIfExists("VERSION_INFO_FILE")
//			versionInfoPrefix = try rawBuildSettings.getIfExists("VERSION_INFO_PREFIX")
//			versionInfoSuffix = try rawBuildSettings.getIfExists("VERSION_INFO_SUFFIX")
		}
	}
	
}

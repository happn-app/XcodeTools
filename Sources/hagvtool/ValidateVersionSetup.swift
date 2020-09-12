import Foundation

import ArgumentParser

import libhagvtool



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		let xcodeprojURL = xcodeproj.xcodeprojURL
		
		try xcodeproj.managedObjectContext.performAndWait{
			let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
			let combinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: xcodeproj.pbxproj.rootObject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			print(combinedBuildSettings.keys)
			print(combinedBuildSettings.mapValues{ $0.keys })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "SRCROOT")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSIONING_SYSTEM")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "CURRENT_PROJECT_VERSION")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_CURRENT_VERSION")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_COMPATIBILITY_VERSION")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "MARKETING_VERSION")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "INFOPLIST_FILE")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_BUILDER")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_EXPORT_DECL")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_FILE")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_PREFIX")] } })
			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_SUFFIX")] } })
		}
	}
	
}

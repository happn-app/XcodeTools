import Foundation

import ArgumentParser
import XcodeProjKit



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		var nErrors = 0
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		let xcodeprojURL = xcodeproj.xcodeprojURL
		
		do {
			var ok = true
			print("")
			print("*** Verifying versioning system")
			try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configurationName, combinedBuildSettings in
				let versioningSystem = combinedBuildSettings[BuildSettingKey(key: "VERSIONING_SYSTEM")]
				if versioningSystem != "apple-generic" {
					ok = false
					nErrors += 1
					print("   -> Unexpected versioning system “\(versioningSystem)” for target “\(targetName)” and configuration “\(configurationName)”")
				}
			}
			if ok {
				print("-> OK")
			} else {
				print("-> FAIL")
				print("The versioning system should be set to “apple-generic” for all targets, though in practice not setting this build setting will not change much.")
			}
		}
		
		do {
			var ok = true
			print("")
			print("*** Verifying sanity of current project version and marketing version in Info.plist")
			try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configurationName, combinedBuildSettings in
				guard let plist = try combinedBuildSettings.infoPlistRaw(xcodeprojURL: xcodeprojURL) else {
					return
				}
				
				let versionString = plist["CFBundleVersion"]
				if versionString as? String != "$(CURRENT_PROJECT_VERSION)" {
					ok = false
					nErrors += 1
					print("   -> Unexpected CFBundleVersion value “\(versionString ?? "<no value>")” in plist file for target “\(targetName)” and configuration “\(configurationName)”")
				}
				
				let shortVersionString = plist["CFBundleShortVersionString"]
				if shortVersionString as? String != "$(MARKETING_VERSION)" {
					ok = false
					nErrors += 1
					print("   -> Unexpected CFBundleShortVersionString value “\(shortVersionString ?? "<no value>")” in plist file for target “\(targetName)” and configuration “\(configurationName)”")
				}
			}
			if ok {
				print("-> OK")
			} else {
				print("-> FAIL")
				print("The CFBundleVersion value should be set to “$(CURRENT_PROJECT_VERSION)” and the CFBundleShortVersionString should be set to “$(MARKETING_VERSION)”.")
				print("Of course, the actual versions should be set in the build settings (either directly in the project or using an xcconfig file).")
			}
		}
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "CURRENT_PROJECT_VERSION")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_CURRENT_VERSION")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_COMPATIBILITY_VERSION")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "MARKETING_VERSION")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_BUILDER")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_EXPORT_DECL")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_FILE")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_PREFIX")] } })
//		try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_SUFFIX")] } })
		
		throw ExitCode(nErrors > 0 ? 1 : 0)
	}
	
}

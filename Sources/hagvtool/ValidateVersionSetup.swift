import Foundation

import ArgumentParser
import XcodeProjKit



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectFolder: ".")
		let xcodeprojURL = xcodeproj.xcodeprojURL
		
		try xcodeproj.managedObjectContext.performAndWait{
			let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
			let combinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: xcodeproj.pbxproj.rootObject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			for (buildSettings, plistPath) in combinedBuildSettings.flatMap({ $0.value.map({ ($0.value, $0.value[BuildSettingKey(key: "INFOPLIST_FILE")]) }) }) {
				guard plistPath.contains("1") else {continue}
				let plistURL = URL(fileURLWithPath: plistPath, isDirectory: false, relativeTo: xcodeprojURL.deletingLastPathComponent())
				let plistData = try Data(contentsOf: plistURL)
				let deserializedPlist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
				if let deserializedPlistObject = deserializedPlist as? [String: Any] {
					for (key, value) in deserializedPlistObject.sorted(by: { $0.key < $1.key }) {
						if let valueStr = value as? String {
							print("“\(key)” -> “\(buildSettings.resolveVariables(in: valueStr))”")
						}
					}
				}
			}
//			print(combinedBuildSettings.keys)
//			print(combinedBuildSettings.mapValues{ $0.keys })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "SRCROOT")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSIONING_SYSTEM")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "CURRENT_PROJECT_VERSION")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_CURRENT_VERSION")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "DYLIB_COMPATIBILITY_VERSION")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "MARKETING_VERSION")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "INFOPLIST_FILE")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_BUILDER")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_EXPORT_DECL")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_FILE")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_PREFIX")] } })
//			try print(combinedBuildSettings.mapValues{ try $0.mapValues{ try $0[BuildSettingKey(serializedKey: "VERSION_INFO_SUFFIX")] } })
		}
	}
	
}

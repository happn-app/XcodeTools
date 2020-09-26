import Foundation

import ArgumentParser
import XcodeProjKit



struct SetBuildVersion : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	@OptionGroup
	var setVersionOptions: SetVersionOptions
	
	@Argument
	var newVersion: String
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		do {
			try runPrivate(xcodeproj: xcodeproj)
		} catch let e as NonDestructiveErrorWrapper {
			throw e.wrapped
		} catch {
			NSLog("%@", "There was an error setting the version of the project. Some files might have been modified.")
			throw error
		}
	}
	
	private struct NonDestructiveErrorWrapper : Error {
		var wrapped: Error
	}
	
	private func runPrivate(xcodeproj: XcodeProj) throws {
		let xcodeprojURL = xcodeproj.xcodeprojURL
		
		var xcconfigsToRewrite = [XCConfigRef]()
		try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configuration, configurationName, combinedBuildSettings in
			if let plistURL = combinedBuildSettings.infoPlistURL(xcodeprojURL: xcodeprojURL) {
				let plistData = try Data(contentsOf: plistURL)
				let deserializedPlist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
				guard let deserializedPlistObject = deserializedPlist as? [String: Any] else {
					throw HagvtoolError(message: "Cannot deserialize plist file at URL \(plistURL) as a [String: Any].")
				}
				
				if deserializedPlistObject["CFBundleVersion"] as? String != "$(CURRENT_PROJECT_VERSION)" {
					switch setVersionOptions.invalidSetupBehaviour {
						case .fail:
							throw NonDestructiveErrorWrapper(wrapped: HagvtoolError(message: "Invalid CFBundleVersion value in plist at path \(plistURL.path). Expected “$(CURRENT_PROJECT_VERSION)”."))
							
						case .fix:
							var deserializedPlistObject = deserializedPlistObject
							deserializedPlistObject["CFBundleVersion"] = "$(CURRENT_PROJECT_VERSION)"
							let reserializedData = try PropertyListSerialization.data(fromPropertyList: deserializedPlistObject, format: .xml, options: 0)
							try reserializedData.write(to: plistURL)
					}
				}
			}
			
			let buildSettingsMatchingBuildVersion = combinedBuildSettings.buildSettings.filter{ $0.value.key.key == "CURRENT_PROJECT_VERSION" }
			if setVersionOptions.invalidSetupBehaviour == .fail && buildSettingsMatchingBuildVersion.count > 1 {
				throw HagvtoolError(message: "CURRENT_PROJECT_VERSION is set in more than one place for target \(targetName).")
			}
			
			let resolvedCurrentBuildVersion = combinedBuildSettings.resolvedValue(for: BuildSettingKey(key: "CURRENT_PROJECT_VERSION"))
			if setVersionOptions.invalidSetupBehaviour == .fail && resolvedCurrentBuildVersion?.sources.count ?? 0 > 1 {
				throw HagvtoolError(message: "CURRENT_PROJECT_VERSION uses variables for target \(targetName).")
			}
			
			/* First let’s remove all references to the current project version */
			for buildSetting in buildSettingsMatchingBuildVersion {
				switch buildSetting.value.location {
					case .none: throw HagvtoolError(message: "Internal error: Got a CURRENT_PROJECT_VERSION build setting without a location.")
					case .xcconfiguration(let config): config.rawBuildSettings?.removeValue(forKey: "CURRENT_PROJECT_VERSION")
					case .xcconfigFile(let xcconfig, lineID: let lineID, for: _):
						xcconfig.value.lines.removeValue(forKey: lineID)
						xcconfigsToRewrite.append(xcconfig)
				}
			}
			
			configuration.rawBuildSettings?["CURRENT_PROJECT_VERSION"] = newVersion
		}
		
		try xcodeproj.managedObjectContext.performAndWait{
			try xcodeproj.managedObjectContext.save()
			try Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8).write(to: xcodeproj.pbxprojURL)
			
			var rewrittenURLs = Set<URL>()
			for xcconfig in xcconfigsToRewrite {
				let url = xcconfig.value.sourceURL
				guard !rewrittenURLs.contains(url) else {continue}
				
				try Data(xcconfig.value.stringSerialization().utf8).write(to: url)
				rewrittenURLs.insert(url)
			}
		}
	}
	
}

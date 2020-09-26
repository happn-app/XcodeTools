import Foundation

import ArgumentParser
import XcodeProjKit



struct SetMarketingVersion : ParsableCommand {
	
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
		try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configuration, configurationName, combinedBuildSettings in
			if let plistURL = combinedBuildSettings.infoPlistURL(xcodeprojURL: xcodeprojURL) {
				let plistData = try Data(contentsOf: plistURL)
				let deserializedPlist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
				guard let deserializedPlistObject = deserializedPlist as? [String: Any] else {
					throw HagvtoolError(message: "Cannot deserialize plist file at URL \(plistURL) as a [String: Any].")
				}
				
				switch setVersionOptions.invalidSetupBehaviour {
					case .fail:
						guard deserializedPlistObject["CFBundleShortVersionString"] as? String == "$(MARKETING_VERSION)" else {
							throw NonDestructiveErrorWrapper(wrapped: HagvtoolError(message: "Invalid CFBundleShortVersionString value in plist at path \(plistURL.path). Expected “$(MARKETING_VERSION)”."))
						}
						
					case .fix:
						var deserializedPlistObject = deserializedPlistObject
						deserializedPlistObject["CFBundleShortVersionString"] = "$(MARKETING_VERSION)"
						let reserializedData = try PropertyListSerialization.data(fromPropertyList: deserializedPlistObject, format: .xml, options: 0)
						try reserializedData.write(to: plistURL)
				}
				
			}
		}
	}
	
}

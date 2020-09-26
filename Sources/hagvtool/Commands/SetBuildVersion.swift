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
		try xcodeproj.iterateCombinedBuildSettingsOfProject{ configuration, configurationName, combinedBuildSettings in
			print(combinedBuildSettings["CURRENT_PROJECT_VERSION"])
		}
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
			
			let resolvedCurrentBuildVersion = combinedBuildSettings.resolvedValue(for: BuildSettingKey(key: "CURRENT_PROJECT_VERSION"))
			print(resolvedCurrentBuildVersion?.sources.map{ $0.value.location.target?.xcID })
			target.buildConfigurationList?.buildConfigurations?.filter{ $0.name == configurationName }.onlyElement?.rawBuildSettings?["CURRENT_PROJECT_VERSION"] = newVersion
			try xcodeproj.managedObjectContext.save()
			try Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8).write(to: xcodeproj.pbxprojURL)
//			guard resolvedCurrentBuildVersion?.sources.count ?? 1 == 1 else {
//				throw HagvtoolError(message: "The CURRENT_PROJECT_VERSION value is not .")
//			}
//			print(resolvedCurrentBuildVersion?.sources)
		}
	}
	
}

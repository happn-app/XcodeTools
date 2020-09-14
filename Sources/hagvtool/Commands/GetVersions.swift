import Foundation

import ArgumentParser
import XcodeProjKit



struct GetVersions : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	@Option
	var failOnMultipleVersions = false
	
	@Option
	var collapseVersion = false
	
	@Option
	var outputFormat = OutputFormat.text
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		let versions = try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configurationName, combinedBuildSettings -> [Output.Version] in
			let plist = try combinedBuildSettings.infoPlistResolved(xcodeprojURL: xcodeproj.xcodeprojURL)
			return [
				Output.Version(
					versionType: .buildVersion,
					targetName: targetName,
					configurationName: configurationName,
					versionSource: .buildConfiguration,
					versionValue: combinedBuildSettings["CURRENT_PROJECT_VERSION"]
				),
				Output.Version(
					versionType: .marketingVersion,
					targetName: targetName,
					configurationName: configurationName,
					versionSource: .buildConfiguration,
					versionValue: combinedBuildSettings["MARKETING_VERSION"]
				),
				plist.flatMap{ plist in
					Output.Version(
						versionType: .buildVersion,
						targetName: targetName,
						configurationName: configurationName,
						versionSource: .plist,
						versionValue: plist["CFBundleVersion"] as? String ?? ""
					)
				},
				plist.flatMap{ plist in
					Output.Version(
						versionType: .marketingVersion,
						targetName: targetName,
						configurationName: configurationName,
						versionSource: .plist,
						versionValue: plist["CFBundleShortVersionString"] as? String ?? ""
					)
				}
			].compactMap{ $0 }
		}.flatMap{ $0 }
		
		let output = Output(versions: versions)
		print(output.unreducedDescription)
	}
	
	private struct Output : Encodable {
		
		struct Version : Encodable {
			
			enum VersionType : String, Encodable {
				
				case marketingVersion = "MarketingVersion"
				case buildVersion = "BuildVersion"
				
			}
			
			enum VersionSourse : String, Encodable {
				
				case buildConfiguration = "config"
				case plist
				
			}
			
			var versionType: VersionType
			
			var targetName: String
			var configurationName: String
			var versionSource: VersionSourse
			
			var versionValue: String
			
		}
		
		var versions: [Version]
		
		var reducedBuildVersionForAll: String?
		var reducedBuildVersionPerTargets: [String: String?]
		var reducedBuildVersionPerConfigurations: [String: String?]
		
		var unreducedDescription: String {
			return versions.map{ version in
				return version.versionType.rawValue.bracketEscaped() + "[" + version.targetName.bracketEscaped() + "][" + version.configurationName.bracketEscaped() + "][" + version.versionSource.rawValue.bracketEscaped() + "] = \"" + version.versionValue.quoteEscaped() + "\""
			}.joined(separator: "\n")
		}
		
		init(versions vs: [Version]) {
			versions = vs.sorted{ v1, v2 in
				if v1.versionType.rawValue < v2.versionType.rawValue {return true}
				if v1.versionType.rawValue > v2.versionType.rawValue {return false}
				
				if v1.targetName < v2.targetName {return true}
				if v1.targetName > v2.targetName {return false}
				
				if v1.configurationName < v2.configurationName {return true}
				if v1.configurationName > v2.configurationName {return false}
				
				if v1.versionSource.rawValue < v2.versionSource.rawValue {return true}
				if v1.versionSource.rawValue > v2.versionSource.rawValue {return false}
				
				return true
			}
			
			reducedBuildVersionForAll = nil
			reducedBuildVersionPerTargets = [:]
			reducedBuildVersionPerConfigurations = [:]
		}
		
	}
	
}

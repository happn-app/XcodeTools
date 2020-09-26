import Foundation

import ArgumentParser
import XcodeProjKit



struct ValidateVersionSetup : ParsableCommand {
	
	@OptionGroup
	var hagvtoolOptions: Hagvtool.Options
	
	func run() throws {
		let xcodeproj = try XcodeProj(path: hagvtoolOptions.pathToXcodeproj, autodetectInFolderAtPath: ".")
		let xcodeprojURL = xcodeproj.xcodeprojURL
		
		let projectMessages = try xcodeproj.iterateCombinedBuildSettingsOfProject{ configurationName, combinedBuildSetting -> [Output.DiagnosticMessage] in
			let currentProjectVersionMessage = combinedBuildSetting.resolvedValue(for: BuildSettingKey(key: "CURRENT_PROJECT_VERSION")).flatMap{ v in
				Output.DiagnosticMessage(messageType: .projectBuildVersionSet, value: v.value, targetName: "", configurationName: configurationName)
			}
			let marketingVersionMessage = combinedBuildSetting.resolvedValue(for: BuildSettingKey(key: "MARKETING_VERSION")).flatMap{ v in
				Output.DiagnosticMessage(messageType: .projectMarketingVersionSet, value: v.value, targetName: "", configurationName: configurationName)
			}
			return [currentProjectVersionMessage, marketingVersionMessage].compactMap{ $0 }
		}.flatMap{ $0 }
		
		let targetMessages = try xcodeproj.iterateCombinedBuildSettingsOfTargets(matchingOptions: hagvtoolOptions){ target, targetName, configurationName, combinedBuildSettings -> [Output.DiagnosticMessage] in
			let plistMessages: [Output.DiagnosticMessage?]
			if let plist = try combinedBuildSettings.infoPlistRaw(xcodeprojURL: xcodeprojURL) {
				let bundleVersion = plist["CFBundleVersion"] as? String
				let bundleVersionMessage = Output.DiagnosticMessage(messageType: .invalidCFBundleVersionInPlist, value: bundleVersion, targetName: targetName, configurationName: configurationName)
				
				let shortVersionString = plist["CFBundleShortVersionString"] as? String
				let shortVersionStringMessage = Output.DiagnosticMessage(messageType: .invalidCFBundleShortVersionStringInPlist, value: shortVersionString, targetName: targetName, configurationName: configurationName)
				
				plistMessages = [
					(bundleVersion      != "$(CURRENT_PROJECT_VERSION)" ? bundleVersionMessage      : nil),
					(shortVersionString != "$(MARKETING_VERSION)"       ? shortVersionStringMessage : nil)
				]
			} else {
				plistMessages = []
			}
			
			let versioningSystem = combinedBuildSettings[BuildSettingKey(key: "VERSIONING_SYSTEM")]
			let versioningSystemMessage = Output.DiagnosticMessage(messageType: .invalidVersioningSystem, value: versioningSystem, targetName: targetName, configurationName: configurationName)
			
			let nonPlistMessages = [
				(versioningSystem != "apple-generic" ? versioningSystemMessage : nil)
			]
			
			return (nonPlistMessages + plistMessages).compactMap{ $0 }
		}.flatMap{ $0 }
		
		let output = Output(messages: projectMessages + targetMessages)
		try Hagvtool.printOutput(output, format: hagvtoolOptions.outputFormat)
		
		if !output.messages.isEmpty {
			throw ExitCode(1)
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
	}
	
	private struct Output : Encodable, CustomStringConvertible {
		
		struct DiagnosticMessage : Encodable {
			
			enum MessageType : String, Encodable {
				
				case projectBuildVersionSet = "build-version-set-project-wide"
				case projectMarketingVersionSet = "marketing-version-set-project-wide"
				
				case invalidVersioningSystem = "invalid-versioning-system"
				case invalidCFBundleVersionInPlist = "invalid-CFBundleVersion-in-plist"
				case invalidCFBundleShortVersionStringInPlist = "invalid-CFBundleShortVersionString-in-plist"
				
			}
			
			var messageType: MessageType
			var value: String?
			
			var targetName: String
			var configurationName: String
			
		}
		
		var messages: [DiagnosticMessage]
		
		var description: String {
			var previousWasSuccess = false
			
			return [
				/* ***** */
				descriptionForMessages(
					ofType: .projectBuildVersionSet,
					checkDescription: "Build version not set project-wide",
					failureExplanation: "The CURRENT_PROJECT_VERSION build setting should be set on a target per target basis, not project-wide.",
					failureToStringHandler: { "CURRENT_PROJECT_VERSION is set to “\($0.value ?? "<not set>")” at the project level for configuration “\($0.configurationName)”" },
					previousWasSuccess: &previousWasSuccess,
					isLast: false
				),
				
				/* ***** */
				descriptionForMessages(
					ofType: .projectMarketingVersionSet,
					checkDescription: "Marketing version not set project-wide",
					failureExplanation: "The MARKETING_VERSION build setting should be set on a target per target basis, not project-wide.",
					failureToStringHandler: { "MARKETING_VERSION is set to “\($0.value ?? "<not set>")” at the project level for configuration “\($0.configurationName)”" },
					previousWasSuccess: &previousWasSuccess,
					isLast: false
				),
				
				/* ***** */
				descriptionForMessages(
					ofType: .invalidVersioningSystem,
					checkDescription: "Versioning system",
					failureExplanation: "The versioning system should be set to “apple-generic” for all targets, though in practice not setting this build setting will not change much.",
					failureToStringHandler: { "Unexpected versioning system “\($0.value ?? "<not set>")” for target “\($0.targetName)” and configuration “\($0.configurationName)”" },
					previousWasSuccess: &previousWasSuccess,
					isLast: false
				),
				
				/* ***** */
				descriptionForMessages(
					ofType: .invalidCFBundleVersionInPlist,
					checkDescription: "CFBundleVersion value check (plist)",
					failureExplanation: """
					The CFBundleVersion value should be set to “$(CURRENT_PROJECT_VERSION)”.
					Of course, the actual version should be set using the CURRENT_PROJECT_VERSION key in the build settings (either directly in the project or using an xcconfig file).
					""",
					failureToStringHandler: { "Unexpected CFBundleVersion value “\($0.value ?? "<not set>")” in plist file for target “\($0.targetName)” and configuration “\($0.configurationName)”" },
					previousWasSuccess: &previousWasSuccess,
					isLast: false
				),
				
				/* ***** */
				descriptionForMessages(
					ofType: .invalidCFBundleShortVersionStringInPlist,
					checkDescription: "CFBundleShortVersionString value check (plist)",
					failureExplanation: """
					The CFBundleShortVersionString should be set to “$(MARKETING_VERSION)”.
					Of course, the actual version should be set using the MARKETING_VERSION key in the build settings (either directly in the project or using an xcconfig file).
					""",
					failureToStringHandler: { "Unexpected CFBundleShortVersionString value “\($0.value ?? "<not set>")” in plist file for target “\($0.targetName)” and configuration “\($0.configurationName)”" },
					previousWasSuccess: &previousWasSuccess,
					isLast: true
				)
			].joined()
		}
		
		init(messages m: [DiagnosticMessage]) {
			messages = m.sorted{ m1, m2 in
				if m1.messageType.rawValue < m2.messageType.rawValue {return true}
				if m1.messageType.rawValue > m2.messageType.rawValue {return false}
				
				if m1.targetName < m2.targetName {return true}
				if m1.targetName > m2.targetName {return false}
				
				if m1.configurationName < m2.configurationName {return true}
				if m1.configurationName > m2.configurationName {return false}
				
				return true
			}
		}
		
		private func descriptionForMessages(
			ofType type: DiagnosticMessage.MessageType,
			checkDescription: String,
			failureExplanation: String,
			failureToStringHandler: (DiagnosticMessage) -> String,
			previousWasSuccess: inout Bool,
			isLast: Bool
		) -> String {
			let filteredMessages = messages.filter{ $0.messageType == type }
			let isFailure = !filteredMessages.isEmpty
			let emoji = (!isFailure ? "✅" : "❌")
			let descriptionBase = filteredMessages.reduce("\(checkDescription): \(emoji)\n" + (isFailure ? failureExplanation + "\n" : ""), { result, diagnostic in
				result + "   - " + failureToStringHandler(diagnostic) + "\n"
			})
			
			let previousWasSuccessLocal = previousWasSuccess
			previousWasSuccess = !isFailure
			
			return (previousWasSuccessLocal && isFailure ? "\n" : "") + descriptionBase + (isFailure && !isLast ? "\n" : "")
		}
		
	}
	
}

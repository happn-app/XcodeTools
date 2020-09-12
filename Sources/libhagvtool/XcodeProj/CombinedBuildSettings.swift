import Foundation



/** Represents multiple build settings levels combined. */
public struct CombinedBuildSettings {
	
	/** `nil` if representing build settings of the project. */
	public var targetName: String?
	public var configurationName: String
	
	/** The first level is the deepest (xcconfig project level if it exists). */
	public var buildSettingsLevels: [BuildSettings]
	
	/**
	Returns a dictionary whose keys are the target names and values are another
	dictionary, whose keys are the configuration names and values are the build
	settings.
	
	- Note: The xcodeproj URL is required because some paths can be relative to
	the xcodeproj path. */
	public static func allCombinedBuildSettingsForTargets(of project: PBXProject, xcodeprojURL: URL) throws -> [String: [String: CombinedBuildSettings]] {
		guard let targets = project.targets else {
			throw HagvtoolError(message: "targets property is not set in project \(project)")
		}
		
		let projectSettingsPerConfigName = try allCombinedBuildSettings(for: project.buildConfigurationList?.buildConfigurations, targetAndProjectSettingsPerConfigName: nil, xcodeprojURL: xcodeprojURL)
			.mapValues{ $0.buildSettingsLevels }
		
		let targetsSettings: [(String, [String : CombinedBuildSettings])] = try targets.map{ target in
			guard let name = target.name else {
				throw HagvtoolError(message: "Got target \(target.xcID ?? "<unknown>") which does not have a name")
			}
			return try (name, allCombinedBuildSettings(for: target.buildConfigurationList?.buildConfigurations, targetAndProjectSettingsPerConfigName: (target, projectSettingsPerConfigName), xcodeprojURL: xcodeprojURL))
		}
		return try Dictionary(targetsSettings, uniquingKeysWith: { (current, new) in
			throw HagvtoolError(message: "Got two targets with the same same; this is not normal.")
		})
	}
	
	/**
	Returns a dictionary whose keys are the configuration names and values are
	the build settings.
	
	- Note: The xcodeproj URL is required because some paths can be relative to
	the xcodeproj path. */
	static func allCombinedBuildSettings(for configurations: [XCBuildConfiguration]?, targetAndProjectSettingsPerConfigName: (PBXTarget, [String: [BuildSettings]])?, xcodeprojURL: URL) throws -> [String: CombinedBuildSettings] {
		guard let configurations = configurations else {
			throw HagvtoolError(message: "configurations property not set")
		}
		
		let settings: [(String, CombinedBuildSettings)] = try configurations.map{ configuration in
			guard let name = configuration.name else {
				throw HagvtoolError(message: "Got configuration \(configuration.xcID ?? "<unknown>") which does not have a name")
			}
			let targetAndProjectSettings: (PBXTarget, [BuildSettings])? = try targetAndProjectSettingsPerConfigName.flatMap{ targetAndProjectSettingsPerConfigName in
				let (target, projectSettingsPerConfigName) = targetAndProjectSettingsPerConfigName
				guard let projectSettings = projectSettingsPerConfigName[name] else {
					throw HagvtoolError(message: "Asked to get combined build settings for target \(target.xcID ?? "<unknown>") but did not get project settings for configuration “\(name)” which is in the target’s configuration list.")
				}
				return (target, projectSettings)
			}
			return (name, try CombinedBuildSettings(configuration: configuration, targetAndProjectSettings: targetAndProjectSettings, xcodeprojURL: xcodeprojURL))
		}
		return try Dictionary(settings, uniquingKeysWith: { (current, new) in
			throw HagvtoolError(message: "Got two configuration with the same same; this is not normal.")
		})
	}
	
	init(configuration: XCBuildConfiguration, targetAndProjectSettings: (PBXTarget, [BuildSettings])?, xcodeprojURL: URL) throws {
		guard let configName = configuration.name else {
			throw HagvtoolError(message: "Trying to init a CombinedBuildSettings w/ configuration \(configuration.xcID ?? "<unknown>") which does not have a name")
		}
		configurationName = configName
		
		var buildSettingsLevelsBuilding = [BuildSettings]()
		
		if let (target, projectSettings) = targetAndProjectSettings {
			guard let name = target.name else {
				throw HagvtoolError(message: "Trying to init a CombinedBuildSettings w/ target \(target.xcID ?? "<unknown>") which does not have a name")
			}
			targetName = name
			buildSettingsLevelsBuilding.append(contentsOf: projectSettings)
		} else {
			targetName = nil
		}
		
		if let baseConfigurationReference = configuration.baseConfigurationReference {
			guard baseConfigurationReference.xcLanguageSpecificationIdentifier == "text.xcconfig" || baseConfigurationReference.lastKnownFileType == "text.xcconfig" else {
				throw HagvtoolError(message: "Got base configuration reference \(baseConfigurationReference.xcID ?? "<unknown>") for configuration \(configuration.xcID ?? "<unknown>") whose language specification index is not text.xcconfig. Don’t known how to handle this.")
			}
			let url = try baseConfigurationReference.resolvedPathAsURL(xcodeprojURL: xcodeprojURL)
			let config = try BuildSettings(xcconfigURL: url)
			buildSettingsLevelsBuilding.append(config)
		}
		
		guard let rawBuildSettings = configuration.rawBuildSettings else {
			throw HagvtoolError(message: "Trying to init a CombinedBuildSettings w/ configuration \(configuration.xcID ?? "<unknown>") which does not have build settings")
		}
		
		let buildSettings = BuildSettings(rawBuildSettings: rawBuildSettings)
		buildSettingsLevelsBuilding.append(buildSettings)
		
		buildSettingsLevels = buildSettingsLevelsBuilding
	}
	
	/**
	Returns the value that matches the given settings key. For now, no variable
	substitution is done.
	
	This method cannot fail and returns a non-optional because if a variable does
	not have a value (does not exist), its value is set to "".
	
	A build setting value could either be a String, or an array of Strings. For
	now, if we encounter an array, we “convert” it to a String.
	The conversion is simply the concatenation of the String values, separated by
	a space. That’s all. And yes, you can loose info if a element contains a
	space, but my testing shows this is how Xcode does it: in an array, for an
	element to be able to contains a space, it MUST be double or simple quoted.
	
	If a build setting have an unknown type (neither a String nor an array of
	Strings), we return en empty String for this value. */
	public subscript(_ key: BuildSettingKey) -> String {
		let searchedSettings = buildSettingsLevels.flatMap{ $0.settings }
		let settingsWhoseKeyMatch = searchedSettings.filter{ $0.key.key == key.key }
		#warning("TODO: Implement variable resolution and stuff…")
		return settingsWhoseKeyMatch.last?.stringValue ?? ""
	}
	
}

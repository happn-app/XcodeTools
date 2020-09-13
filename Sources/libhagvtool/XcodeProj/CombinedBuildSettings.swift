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
	public static func allCombinedBuildSettingsForTargets(of project: PBXProject, xcodeprojURL: URL, defaultBuildSettings: BuildSettings) throws -> [String: [String: CombinedBuildSettings]] {
		guard let targets = project.targets else {
			throw HagvtoolError(message: "targets property is not set in project \(project)")
		}
		
		let projectSettingsPerConfigName = try allCombinedBuildSettings(for: project.buildConfigurationList?.buildConfigurations, targetAndProjectSettingsPerConfigName: nil, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			.mapValues{ $0.buildSettingsLevels }
		
		let targetsSettings: [(String, [String : CombinedBuildSettings])] = try targets.map{ target in
			guard let name = target.name else {
				throw HagvtoolError(message: "Got target \(target.xcID ?? "<unknown>") which does not have a name")
			}
			return try (name, allCombinedBuildSettings(for: target.buildConfigurationList?.buildConfigurations, targetAndProjectSettingsPerConfigName: (target, projectSettingsPerConfigName), xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings))
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
	static func allCombinedBuildSettings(for configurations: [XCBuildConfiguration]?, targetAndProjectSettingsPerConfigName: (PBXTarget, [String: [BuildSettings]])?, xcodeprojURL: URL, defaultBuildSettings: BuildSettings) throws -> [String: CombinedBuildSettings] {
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
			return (name, try CombinedBuildSettings(configuration: configuration, targetAndProjectSettings: targetAndProjectSettings, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings))
		}
		return try Dictionary(settings, uniquingKeysWith: { (current, new) in
			throw HagvtoolError(message: "Got two configuration with the same same; this is not normal.")
		})
	}
	
	init(configuration: XCBuildConfiguration, targetAndProjectSettings: (PBXTarget, [BuildSettings])?, xcodeprojURL: URL, defaultBuildSettings: BuildSettings) throws {
		guard let configName = configuration.name else {
			throw HagvtoolError(message: "Trying to init a CombinedBuildSettings w/ configuration \(configuration.xcID ?? "<unknown>") which does not have a name")
		}
		configurationName = configName
		
		var buildSettingsLevelsBuilding = [defaultBuildSettings]
		
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
	
	public init(targetName: String? = nil, configurationName: String, buildSettingsLevels: [BuildSettings]) {
		self.targetName = targetName
		self.configurationName = configurationName
		self.buildSettingsLevels = buildSettingsLevels
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
		return resolvedValue(for: key) ?? ""
	}
	
	/** Returns `nil` if the key does not exist in the settings. */
	public func resolvedValue(for key: BuildSettingKey) -> String? {
		/* We want to retrieve an array of (Int, BuildSetting), where the Int
		 * represents the level from which the build setting is from.
		 * I did this because I though I’d need this, but I actually won’t.
		 * Note that the pre-Xcode-10 way of resolving variables needed this I
		 * think! https://stackoverflow.com/a/50731052
		 * Basically before Xcode 10 I think the equivalent BuildSettings internal
		 * structure in Xcode held its settings as a dictionary instead of an
		 * array of BuildSetting, which prevented it from doing the smarter
		 * resolution it now has. */
		let searchedSettings = buildSettingsLevels.enumerated().flatMap{ elementAndOffset in elementAndOffset.element.settings.map{ (level: elementAndOffset.offset, setting: $0) } }
		#warning("TODO: Implement variable conditionals…")
		let settingsWhoseKeyMatch = searchedSettings.filter{ $0.setting.key.key == key.key }
		
		guard !settingsWhoseKeyMatch.isEmpty else {
			return nil
		}
		
		var resolvedValue = ""
		var currentlyResolvedValues = [key.key: resolvedValue]
		for rawValue in settingsWhoseKeyMatch.map({ $0.setting.stringValue }) {
			let scanner = Scanner(forParsing: rawValue)
			resolvedValue = resolveVariables(scanner: scanner, currentlyResolvedValues: &currentlyResolvedValues, inheritedVariableName: key.key)
			currentlyResolvedValues[key.key] = resolvedValue
		}
		
		return resolvedValue
	}
	
	public func resolveVariables(in string: String) -> String {
		let scanner = Scanner(forParsing: string)
		var currentlyResolvedValues = [String: String]()
		return resolveVariables(scanner: scanner, currentlyResolvedValues: &currentlyResolvedValues)
	}
	
	/**
	Resolve the variables in the given string (via a Scanner).
	
	varEndChars contains the characters that should end the parsing of the
	variable (for embedded variables). Always call with an empty string first to
	parse the whole string.
	
	Example: $(VAR1_${VAR2}), when parser is called first, the value will be an
	empty string, then “`)`” then “`}`”.
	
	The inheritedVariableName is given to resolve the “inherited” variable name. */
	private func resolveVariables(scanner: Scanner, currentlyResolvedValues: inout [String: String], inheritedVariableName: String? = nil, varEndChars: String = "") -> String {
		var result = ""
		
		/** Returns `true` if a potential variable start has been found. */
		func parseUpToStartOfVariableIncludingDollar() -> Bool {
			result.append(scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "$" + varEndChars)) ?? "")
			
			if scanner.scanString("$") != nil {
				/* If we have found a dollar sign, we have found the potential start
				 * of a variable. We return true. */
				return true
			}
			
			/* Now we still have to parse a potential stray character (the end char
			 * or something else, if we just parsed a variable without parenthesis,
			 * in which case we don’t want to parse it, that’s why we come back to
			 * previous location is scanned char is not in varEndChars). */
			let scanIndex = scanner.currentIndex
			if let c = scanner.scanCharacter(), !varEndChars.contains(c) {
				scanner.currentIndex = scanIndex
			}
			return false
		}
		
		while parseUpToStartOfVariableIncludingDollar() {
			/* We might have reached the start of a variable. Let’s verify that.
			 * AFAICT (from the tests in the project 1 in the tests data), the only
			 * way to _not_ have a variable start is to parse a dollar here. */
			guard scanner.scanString("$") == nil else {
				result.append("$")
				continue
			}
			
			let mustExist: Bool
			let rawVariableName: String
			if scanner.scanString("(") != nil {
				mustExist = false
				rawVariableName = resolveVariables(scanner: scanner, currentlyResolvedValues: &currentlyResolvedValues, varEndChars: ")")
			} else if scanner.scanString("{") != nil {
				mustExist = false
				rawVariableName = resolveVariables(scanner: scanner, currentlyResolvedValues: &currentlyResolvedValues, varEndChars: "}")
			} else {
				mustExist = true
				rawVariableName = scanner.scanCharacters(from: BuildSettings.charactersValidInVariableName) ?? ""
			}
			
			let variableName: String
			if rawVariableName == "inherited" {variableName = inheritedVariableName ?? ""}
			else                              {variableName = rawVariableName}
			
			let resolvedOptional = currentlyResolvedValues[variableName] ?? resolvedValue(for: BuildSettingKey(key: variableName, parameters: []))
			let resolved: String
			if let r = resolvedOptional {resolved = r}
			else if mustExist           {resolved = "$" + variableName}
			else                        {resolved = ""}
			
			currentlyResolvedValues[variableName] = resolved
			result.append(resolved)
		}
		
		return result
	}
	
}

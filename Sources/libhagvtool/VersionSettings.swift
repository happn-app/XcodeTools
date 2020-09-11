import CoreData
import Foundation



public struct VersionSettings : Equatable {
	
	public static let expectedVersioningSystem = "apple-generic"
	
	/** `nil` if representing version settings of the project. */
	public var targetName: String?
	
	public var configurationName: String
	
	/** `VERSIONING_SYSTEM` */
	public var versioningSystem: String?
	
	/** `CURRENT_PROJECT_VERSION` */
	public var currentProjectVersion: String?
	
	/** `DYLIB_CURRENT_VERSION` */
	public var currentLibraryVersion: String?
	
	/** `DYLIB_COMPATIBILITY_VERSION` */
	public var compatibilityLibraryVersion: String?
	
	/** `MARKETING_VERSION` */
	public var marketingVersion: String?
	
	/** `INFOPLIST_FILE` */
	public var infoPlistPath: String?
	
	/** `VERSION_INFO_BUILDER` */
	public var versionInfoBuilder: String?
	
	/** `VERSION_INFO_EXPORT_DECL` */
	public var versionInfoExportDeclaration: String?
	
	/** `VERSION_INFO_FILE` */
	public var versionInfoFile: String?
	
	/** `VERSION_INFO_PREFIX` */
	public var versionInfoPrefix: String?
	
	/** `VERSION_INFO_SUFFIX` */
	public var versionInfoSuffix: String?
	
//	static func allVersionSettings(project: PBXProject) throws -> [String: (project: VersionSettings, targets: [String: VersionSettings])] {
//	}
	
	/* Note: The xcodeproj URL is required because some paths can be relative to
	 * the xcodeproj path. */
	public static func allVersionSettings(project: PBXProject, xcodeprojURL: URL) throws -> [VersionSettings] {
		guard let targets = project.targets else {
			throw HagvtoolError(message: "targets property is not set in project \(project)")
		}
		
		return try (
			allVersionSettings(configurations: project.buildConfigurationList?.buildConfigurations, target: nil, xcodeprojURL: xcodeprojURL) +
			targets.flatMap{ try allVersionSettings(configurations: $0.buildConfigurationList?.buildConfigurations, target: $0, xcodeprojURL: xcodeprojURL) }
		)
	}
	
	static func allVersionSettings(configurations: [XCBuildConfiguration]?, target: PBXTarget?, xcodeprojURL: URL) throws -> [VersionSettings] {
		guard let configurations = configurations else {
			throw HagvtoolError(message: "configurations property not set")
		}
		
		return try configurations.map{ try VersionSettings(configuration: $0, configurationName: $0.name, target: target, xcodeprojURL: xcodeprojURL) }
	}
	
	init(configuration: XCBuildConfiguration, configurationName configName: String?, target: PBXTarget?, xcodeprojURL: URL) throws {
		guard let configName = configName else {
			throw HagvtoolError(message: "No configuration name given to init a VersionSettings")
		}
		configurationName = configName
		
		if let target = target {
			guard let name = target.name else {
				throw HagvtoolError(message: "Trying to init a VersionSettings w/ target \(target.xcID ?? "<unknown>") which does not have a name")
			}
			targetName = name
		} else {
			targetName = nil
		}
		
		guard let rawBuildSettings = configuration.rawBuildSettings else {
			throw HagvtoolError(message: "Trying to init a VersionSettings w/ configuration \(configuration.xcID ?? "<unknown>") which does not have build settings")
		}
		
		if let baseConfigurationReference = configuration.baseConfigurationReference {
			guard baseConfigurationReference.xcLanguageSpecificationIdentifier == "text.xcconfig" || baseConfigurationReference.lastKnownFileType == "text.xcconfig" else {
				throw HagvtoolError(message: "Got base configuration reference \(baseConfigurationReference.xcID ?? "<unknown>") for configuration \(configuration.xcID ?? "<unknown>") whose language specification index is not text.xcconfig. Don’t known how to handle this.")
			}
			let url = try baseConfigurationReference.resolvedPathAsURL(xcodeprojURL: xcodeprojURL)
			let config = try XCConfig(url: url)
			print(config.settings)
		}
		
		versioningSystem = try rawBuildSettings.getIfExists("VERSIONING_SYSTEM")
		currentProjectVersion = try rawBuildSettings.getIfExists("CURRENT_PROJECT_VERSION")
		currentLibraryVersion = try rawBuildSettings.getIfExists("DYLIB_CURRENT_VERSION")
		compatibilityLibraryVersion = try rawBuildSettings.getIfExists("DYLIB_COMPATIBILITY_VERSION")
		marketingVersion = try rawBuildSettings.getIfExists("MARKETING_VERSION")
		infoPlistPath = try rawBuildSettings.getIfExists("INFOPLIST_FILE")
		versionInfoBuilder = try rawBuildSettings.getIfExists("VERSION_INFO_BUILDER")
		versionInfoExportDeclaration = try rawBuildSettings.getIfExists("VERSION_INFO_EXPORT_DECL")
		versionInfoFile = try rawBuildSettings.getIfExists("VERSION_INFO_FILE")
		versionInfoPrefix = try rawBuildSettings.getIfExists("VERSION_INFO_PREFIX")
		versionInfoSuffix = try rawBuildSettings.getIfExists("VERSION_INFO_SUFFIX")
	}
	
}

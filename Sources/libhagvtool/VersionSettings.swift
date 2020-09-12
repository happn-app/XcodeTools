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
	
}

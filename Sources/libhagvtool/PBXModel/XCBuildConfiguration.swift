import CoreData
import Foundation



@objc(XCBuildConfiguration)
public class XCBuildConfiguration : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"rawBuildSettings": "buildSettings"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.get("name")
		
		rawBuildSettings = try rawObject.get("buildSettings")
		
		buildSetting_INFOPLIST_FILE = try rawBuildSettings?.getIfExists("INFOPLIST_FILE")
		buildSetting_MARKETING_VERSION = try rawBuildSettings?.getIfExists("MARKETING_VERSION")
		buildSetting_VERSIONING_SYSTEM = try rawBuildSettings?.getIfExists("VERSIONING_SYSTEM")
		buildSetting_VERSION_INFO_FILE = try rawBuildSettings?.getIfExists("VERSION_INFO_FILE")
		buildSetting_VERSION_INFO_PREFIX = try rawBuildSettings?.getIfExists("VERSION_INFO_PREFIX")
		buildSetting_VERSION_INFO_SUFFIX = try rawBuildSettings?.getIfExists("VERSION_INFO_SUFFIX")
		buildSetting_VERSION_INFO_BUILDER = try rawBuildSettings?.getIfExists("VERSION_INFO_BUILDER")
		buildSetting_DYLIB_CURRENT_VERSION = try rawBuildSettings?.getIfExists("DYLIB_CURRENT_VERSION")
		buildSetting_CURRENT_PROJECT_VERSION = try rawBuildSettings?.getIfExists("CURRENT_PROJECT_VERSION")
		buildSetting_DYLIB_COMPATIBILITY_VERSION = try rawBuildSettings?.getIfExists("DYLIB_COMPATIBILITY_VERSION")
		buildSetting_VERSION_INFO_EXPORT_DECL = try rawBuildSettings?.getIfExists("VERSION_INFO_EXPORT_DECL")
	}
	
}

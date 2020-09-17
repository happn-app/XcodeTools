import CoreData
import Foundation



@objc(XCBuildConfiguration)
public class XCBuildConfiguration : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
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
		
		let baseConfigurationReferenceID: String? = try rawObject.getIfExists("baseConfigurationReference")
		baseConfigurationReference = try baseConfigurationReferenceID.flatMap{ try PBXFileReference.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	open override func stringSerializationName(projectName: String) -> String? {
		return name
	}
	
}

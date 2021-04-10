import CoreData
import Foundation



@objc(XCBuildConfiguration)
public class XCBuildConfiguration : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"rawBuildSettings": "buildSettings"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.getForParse("name", xcID)
		
		rawBuildSettings = try rawObject.getForParse("buildSettings", xcID)
		
		let baseConfigurationReferenceID: String? = try rawObject.getIfExistsForParse("baseConfigurationReference", xcID)
		baseConfigurationReference = try baseConfigurationReferenceID.flatMap{ try PBXFileReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	open override func stringSerializationName(projectName: String) -> String? {
		return name
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let c = baseConfigurationReference {mySerialization["baseConfigurationReference"] = try c.getIDAndCommentForSerialization("baseConfigurationReference", xcID, projectName: projectName)}
		mySerialization["name"]          = try name.getForSerialization("name", xcID)
		mySerialization["buildSettings"] = try rawBuildSettings.getForSerialization("buildSettings", xcID)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

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
		
		name = try rawObject.get("name")
		
		rawBuildSettings = try rawObject.get("buildSettings")
		
		let baseConfigurationReferenceID: String? = try rawObject.getIfExists("baseConfigurationReference")
		baseConfigurationReference = try baseConfigurationReferenceID.flatMap{ try PBXFileReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	open override func stringSerializationName(projectName: String) -> String? {
		return name
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let c = baseConfigurationReference {mySerialization["baseConfigurationReference"] = try c.xcIDAndComment(projectName: projectName).get()}
		mySerialization["name"]          = try name.get()
		mySerialization["buildSettings"] = try rawBuildSettings.get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

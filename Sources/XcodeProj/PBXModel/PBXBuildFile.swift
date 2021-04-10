import CoreData
import Foundation



@objc(PBXBuildFile)
public class PBXBuildFile : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"rawSettings": "settings"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		rawSettings = try rawObject.getIfExists("settings")
		
		let fileRefID: String? = try rawObject.getIfExists("fileRef")
		fileRef = try fileRefID.flatMap{ try PBXFileElement.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let productRefID: String? = try rawObject.getIfExists("productRef")
		productRef = try productRefID.flatMap{ try XCSwiftPackageProductDependency.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	open override var oneLineStringSerialization: Bool {
		return true
	}
	
	open override func stringSerializationName(projectName: String) -> String? {
		let fileName = fileRef?.name ?? productRef?.productName ?? "(null)"
		let buildPhaseName = buildPhase?.stringSerializationName(projectName: projectName) ?? "(null)"
		return fileName + " in " + buildPhaseName
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let s = rawSettings {mySerialization["settings"]   = s}
		if let r = fileRef     {mySerialization["fileRef"]    = try r.xcIDAndComment(projectName: projectName).get()}
		if let r = productRef  {mySerialization["productRef"] = try r.xcIDAndComment(projectName: projectName).get()}
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

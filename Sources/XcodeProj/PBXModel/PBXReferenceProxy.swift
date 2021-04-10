import CoreData
import Foundation



@objc(PBXReferenceProxy)
public class PBXReferenceProxy : PBXFileElement {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		fileType = try rawObject.get("fileType")
		
		let remoteRefID: String = try rawObject.get("remoteRef")
		remoteRef = try PBXContainerItemProxy.unsafeInstantiate(id: remoteRefID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["fileType"]  = try fileType.get()
		mySerialization["remoteRef"] = try remoteRef.get().xcIDAndComment(projectName: projectName).get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

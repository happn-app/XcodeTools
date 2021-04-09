import CoreData
import Foundation



@objc(PBXReferenceProxy)
public class PBXReferenceProxy : PBXFileElement {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		fileType = try rawObject.get("fileType")
		
		let remoteRefID: String = try rawObject.get("remoteRef")
		remoteRef = try PBXContainerItemProxy.unsafeInstantiate(rawObjects: rawObjects, id: remoteRefID, context: context, decodedObjects: &decodedObjects)
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["fileType"]  = try fileType.get()
		mySerialization["remoteRef"] = try remoteRef.get().xcIDAndComment(projectName: projectName).get()
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

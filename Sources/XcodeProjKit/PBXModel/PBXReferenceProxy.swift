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
	
}

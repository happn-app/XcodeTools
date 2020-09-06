import CoreData
import Foundation



@objc(PBXBuildFile)
public class PBXBuildFile : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let fileRefID: String? = try rawObject.getIfExists("fileRef")
		fileRef = try fileRefID.flatMap{ try PBXFileElement.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
}

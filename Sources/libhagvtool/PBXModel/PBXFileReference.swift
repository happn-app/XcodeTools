import CoreData
import Foundation



@objc(PBXFileReference)
public class PBXFileReference : PBXGroup {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
//		guard children?.isEmpty ?? true else {
//			throw HagvtoolError(message: "Got file reference \(id ?? "<no id>") that has \(children!.count) children!")
//		}
	}
	
}

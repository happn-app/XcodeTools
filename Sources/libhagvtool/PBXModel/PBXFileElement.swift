import CoreData
import Foundation



/* From http://www.monobjc.net/xcode-project-file-format.html */
@objc(PBXFileElement)
public class PBXFileElement : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		sourceTree = try rawObject.get("sourceTree")
		name = try rawObject.getIfExists("name")
		path = try rawObject.getIfExists("path")
	}
	
}

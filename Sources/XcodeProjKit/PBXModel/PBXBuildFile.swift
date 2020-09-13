import CoreData
import Foundation



@objc(PBXBuildFile)
public class PBXBuildFile : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"rawSettings": "settings",
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		rawSettings = try rawObject.getIfExists("settings")
		
		let fileRefID: String? = try rawObject.getIfExists("fileRef")
		fileRef = try fileRefID.flatMap{ try PBXFileElement.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let productRefID: String? = try rawObject.getIfExists("productRef")
		productRef = try productRefID.flatMap{ try XCSwiftPackageProductDependency.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
}

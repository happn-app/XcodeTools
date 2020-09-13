import CoreData
import Foundation



@objc(XCSwiftPackageProductDependency)
public class XCSwiftPackageProductDependency : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		productName = try rawObject.get("productName")
		
		let packageID: String? = try rawObject.getIfExists("package")
		package = try packageID.flatMap{ try XCRemoteSwiftPackageReference.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
}

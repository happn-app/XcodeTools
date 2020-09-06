import CoreData
import Foundation



@objc(PBXTargetDependency)
public class PBXTargetDependency : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let productRefID: String? = try rawObject.getIfExists("productRef")
		productRef = try productRefID.flatMap{ try XCSwiftPackageProductDependency.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let targetID: String? = try rawObject.getIfExists("target")
		target = try targetID.flatMap{ try PBXTarget.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let targetProxyID: String? = try rawObject.getIfExists("targetProxy")
		targetProxy = try targetProxyID.flatMap{ try PBXContainerItemProxy.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
}

import CoreData
import Foundation



@objc(PBXTargetDependency)
public class PBXTargetDependency : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.getIfExists("name")
		
		let productRefID: String? = try rawObject.getIfExists("productRef")
		productRef = try productRefID.flatMap{ try XCSwiftPackageProductDependency.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let targetID: String? = try rawObject.getIfExists("target")
		target = try targetID.flatMap{ try PBXTarget.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let targetProxyID: String? = try rawObject.getIfExists("targetProxy")
		targetProxy = try targetProxyID.flatMap{ try PBXContainerItemProxy.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let n = name        {mySerialization["name"] = n}
		if let r = productRef  {mySerialization["productRef"] = try r.xcIDAndComment(projectName: projectName).get()}
		if let t = target      {mySerialization["target"] = try t.xcIDAndComment(projectName: projectName).get()}
		if let t = targetProxy {mySerialization["targetProxy"] = try t.xcIDAndComment(projectName: projectName).get()}
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

import CoreData
import Foundation



@objc(PBXTargetDependency)
public class PBXTargetDependency : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.getIfExists("name")
		platformFilter = try rawObject.getIfExists("platformFilter")
		
		let productRefID: String? = try rawObject.getIfExists("productRef")
		productRef = try productRefID.flatMap{ try XCSwiftPackageProductDependency.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let targetID: String? = try rawObject.getIfExists("target")
		target = try targetID.flatMap{ try PBXTarget.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let targetProxyID: String? = try rawObject.getIfExists("targetProxy")
		targetProxy = try targetProxyID.flatMap{ try PBXContainerItemProxy.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return "PBXTargetDependency"
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let n = name           {mySerialization["name"] = n}
		if let f = platformFilter {mySerialization["platformFilter"] = f}
		if let r = productRef     {mySerialization["productRef"] = try r.xcIDAndComment(projectName: projectName).get()}
		if let t = target         {mySerialization["target"] = try t.xcIDAndComment(projectName: projectName).get()}
		if let t = targetProxy    {mySerialization["targetProxy"] = try t.xcIDAndComment(projectName: projectName).get()}
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

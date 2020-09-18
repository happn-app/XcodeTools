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
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let p = package {mySerialization["package"] = try p.xcIDAndComment(projectName: projectName).get()}
		mySerialization["productName"] = try productName.get()
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return productName
	}
	
}

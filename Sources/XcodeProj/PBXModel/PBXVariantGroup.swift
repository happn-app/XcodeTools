import CoreData
import Foundation



@objc(PBXVariantGroup)
public class PBXVariantGroup : PBXFileElement {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"children_cd": "children"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let childrenIDs: [String] = try rawObject.get("children")
		children = try childrenIDs.map{ try PBXFileReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	public var children: [PBXFileReference]? {
		get {PBXObject.getOptionalToMany(children_cd, children_isSet)}
		set {(children_cd, children_isSet) = PBXObject.setOptionalToManyTuple(newValue)}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["children"] = try children.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

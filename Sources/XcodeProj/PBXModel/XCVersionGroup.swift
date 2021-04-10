import CoreData
import Foundation



@objc(XCVersionGroup)
public class XCVersionGroup : PBXFileElement {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"children_cd": "children"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		versionGroupType = try rawObject.get("versionGroupType")
		
		let currentVersionID: String = try rawObject.get("currentVersion")
		currentVersion = try PBXFileReference.unsafeInstantiate(id: currentVersionID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
		
		let childrenIDs: [String] = try rawObject.get("children")
		children = try childrenIDs.map{ try PBXFileReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	public var children: [PBXFileReference]? {
		get {children_cd?.array as! [PBXFileReference]?}
		set {children_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["versionGroupType"] = try versionGroupType.get()
		mySerialization["currentVersion"] = try currentVersion.get().xcIDAndComment(projectName: projectName).get()
		mySerialization["children"] = try children.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

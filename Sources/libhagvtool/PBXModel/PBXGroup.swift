import CoreData
import Foundation



@objc(PBXGroup)
public class PBXGroup : PBXFileElement {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		sourceTree = try rawObject.get("sourceTree")
		
		let childrenIDs: [String]? = try rawObject.getIfExists("children")
		children = try childrenIDs?.map{ try PBXGroup.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	public var children: [PBXGroup]? {
		get {children_cd?.array as! [PBXGroup]?}
		set {children_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
}

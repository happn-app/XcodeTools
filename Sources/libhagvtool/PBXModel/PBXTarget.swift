import CoreData
import Foundation



@objc(PBXTarget)
public class PBXTarget : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"buildPhases_cd": "buildPhases"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.get("name")
		
		let buildPhasesIDs: [String] = try rawObject.get("buildPhases")
		buildPhases = try buildPhasesIDs.map{ try PBXBuildPhase.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	public var buildPhases: [PBXBuildPhase]? {
		get {buildPhases_cd?.array as! [PBXBuildPhase]?}
		set {buildPhases_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
}

import CoreData
import Foundation



@objc(PBXNativeTarget)
public class PBXNativeTarget : PBXTarget {
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"buildRules_cd": "buildRules"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let buildConfigurationListID: String = try rawObject.get("buildConfigurationList")
		buildConfigurationList = try XCConfigurationList.unsafeInstantiate(rawObjects: rawObjects, id: buildConfigurationListID, context: context, decodedObjects: &decodedObjects)
		
		let buildRulesIDs: [String] = try rawObject.get("buildRules")
		buildRules = try buildRulesIDs.map{ try PBXBuildRule.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	public var buildRules: [PBXBuildRule]? {
		get {buildRules_cd?.array as! [PBXBuildRule]?}
		set {buildRules_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
}

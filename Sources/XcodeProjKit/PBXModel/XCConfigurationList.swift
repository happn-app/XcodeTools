import CoreData
import Foundation



@objc(XCConfigurationList)
public class XCConfigurationList : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		let mine = [
			"buildConfigurations_cd": "buildConfigurations",
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		defaultConfigurationName = try rawObject.getIfExists("defaultConfigurationName")
		
		/* No idea what defaultConfigurationIsVisible changes, but it exists… */
		let defaultConfigurationIsVisibleStr: String = try rawObject.get("defaultConfigurationIsVisible")
		switch try rawObject.get("defaultConfigurationIsVisible") as String {
			case "0": defaultConfigurationIsVisible = false
			case "1": defaultConfigurationIsVisible = true /* I’ve never encountered this case; I assume the value would be 1 for a true value. */
			default:
				NSLog("%@", "Warning: Unknown defaultConfigurationIsVisible value: \(defaultConfigurationIsVisibleStr)")
				defaultConfigurationIsVisible = nil
		}
		
		let buildConfigurationIDs: [String] = try rawObject.get("buildConfigurations")
		buildConfigurations = try buildConfigurationIDs.map{ try XCBuildConfiguration.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	public var buildConfigurations: [XCBuildConfiguration]? {
		get {buildConfigurations_cd?.array as! [XCBuildConfiguration]?}
		set {buildConfigurations_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public override var stringSerializationName: String? {
		let usedByType: String
		let usedByName: String
		if let p = project {
			usedByType = p.rawISA ?? "<unknown project type>"
			#warning("TODO")
			usedByName = "TODO"
		} else if let t = target {
			usedByType = t.rawISA ?? "<unknown target type>"
			usedByName = t.name ?? "<unknown targe name>"
		} else {
			NSLog("%@", "Warning: Cannot get stringSerializationName for configuration list \(xcID ?? "<nil>") because both the project and target relationships are nil.")
			return nil
		}
		return "Build configuration list for \(usedByType) \"\(usedByName)\""
	}
	
}

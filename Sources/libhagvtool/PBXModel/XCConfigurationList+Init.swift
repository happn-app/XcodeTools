import CoreData
import Foundation



@objc(XCConfigurationList)
public class XCConfigurationList : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		defaultConfigurationName = try rawObject.get("defaultConfigurationName")
		
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
	
}

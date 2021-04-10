import CoreData
import Foundation



@objc(XCConfigurationList)
public class XCConfigurationList : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"buildConfigurations_cd": "buildConfigurations"
		])
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
				XcodeProjConfig.logger?.warning("Unknown defaultConfigurationIsVisible value: \(defaultConfigurationIsVisibleStr)")
				defaultConfigurationIsVisible = nil
		}
		
		let buildConfigurationIDs: [String] = try rawObject.get("buildConfigurations")
		buildConfigurations = try buildConfigurationIDs.map{ try XCBuildConfiguration.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	public var buildConfigurations: [XCBuildConfiguration]? {
		get {buildConfigurations_cd?.array as! [XCBuildConfiguration]?}
		set {buildConfigurations_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	open override func stringSerializationName(projectName: String) -> String? {
		let usedByType: String
		let usedByName: String
		if let p = project_ {
			usedByType = p.rawISA ?? "(null)"
			usedByName = projectName
		} else if let t = target_ {
			usedByType = t.rawISA ?? "(null)"
			usedByName = t.name ?? "(null)"
		} else {
			XcodeProjConfig.logger?.warning("Cannot get stringSerializationName for configuration list \(xcID ?? "<nil>") because both the project and target relationships are nil.")
			return nil
		}
		return "Build configuration list for \(usedByType) \"\(usedByName)\""
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let n = defaultConfigurationName                 {mySerialization["defaultConfigurationName"] = n}
		if let v = defaultConfigurationIsVisible?.boolValue {mySerialization["defaultConfigurationIsVisible"] = v ? "1" : "0"}
		mySerialization["buildConfigurations"] = try buildConfigurations.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

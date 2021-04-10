import CoreData
import Foundation



@objc(PBXTarget)
public class PBXTarget : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"buildPhases_cd": "buildPhases",
			"dependencies_cd": "dependencies"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.get("name")
		productName = try rawObject.get("productName")
		
		let dependenciesIDs: [String] = try rawObject.get("dependencies")
		dependencies = try dependenciesIDs.map{ try PBXTargetDependency.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let buildPhasesIDs: [String] = try rawObject.get("buildPhases")
		buildPhases = try buildPhasesIDs.map{ try PBXBuildPhase.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let buildConfigurationListID: String = try rawObject.get("buildConfigurationList")
		buildConfigurationList = try XCConfigurationList.unsafeInstantiate(id: buildConfigurationListID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
	}
	
	public var buildPhases: [PBXBuildPhase]? {
		get {buildPhases_cd?.array as! [PBXBuildPhase]?}
		set {buildPhases_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public var dependencies: [PBXTargetDependency]? {
		get {dependencies_cd?.array as! [PBXTargetDependency]?}
		set {dependencies_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return name
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["name"]                   = try name.get()
		mySerialization["productName"]            = try productName.get()
		mySerialization["dependencies"]           = try dependencies.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		mySerialization["buildPhases"]            = try buildPhases.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		mySerialization["buildConfigurationList"] = try buildConfigurationList.get().xcIDAndComment(projectName: projectName).get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

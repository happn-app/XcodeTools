import CoreData
import Foundation



@objc(PBXProject)
public class PBXProject : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		compatibilityVersion = try rawObject.get("compatibilityVersion")
		
		projectRoot = try rawObject.get("projectRoot")
		projectDirPath = try rawObject.get("projectDirPath")
		guard projectRoot == "", projectDirPath == "" else {
			throw HagvtoolError(message: "Don’t know how to handle non-empty projectRoot or projectDirPath.")
		}
		
		let targetIDs: [String] = try rawObject.get("targets")
		targets = try targetIDs.map{ try PBXTarget.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let buildConfigurationListID: String = try rawObject.get("buildConfigurationList")
		buildConfigurationList = try XCConfigurationList.unsafeInstantiate(rawObjects: rawObjects, id: buildConfigurationListID, context: context, decodedObjects: &decodedObjects)
	}
	
	public var targets: [PBXTarget]? {
		get {targets_cd?.array as! [PBXTarget]?}
		set {targets_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
}

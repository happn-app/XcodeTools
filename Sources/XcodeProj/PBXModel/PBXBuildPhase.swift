import CoreData
import Foundation



@objc(PBXBuildPhase)
public class PBXBuildPhase : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"files_cd": "files"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.getIfExists("name")
		
		let filesIDs: [String] = try rawObject.get("files")
		files = try filesIDs.map{ try PBXBuildFile.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		if let buildActionMaskStr: String = try rawObject.getIfExists("buildActionMask") {
			guard let value = Int32(buildActionMaskStr) else {
				throw XcodeProjError.parseError(.unexpectedPropertyValue(propertyName: "buildActionMask", value: buildActionMaskStr), objectID: xcID)
			}
			buildActionMask = NSNumber(value: value)
		}
		if let runOnlyForDeploymentPostprocessingStr: String = try rawObject.getIfExists("runOnlyForDeploymentPostprocessing") {
			guard let value = Int16(runOnlyForDeploymentPostprocessingStr) else {
				throw XcodeProjError(message: "Unexpected run only for deployment postprocessing value \(runOnlyForDeploymentPostprocessingStr)")
			}
			if value != 0 && value != 1 {
				XcodeProjConfig.logger?.warning("Unknown value for runOnlyForDeploymentPostprocessing \(runOnlyForDeploymentPostprocessingStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			runOnlyForDeploymentPostprocessing = NSNumber(value: value != 0)
		}
	}
	
	public var files: [PBXBuildFile]? {
		get {files_cd?.array as! [PBXBuildFile]?}
		set {files_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return name ?? buildPhaseBaseTypeAsString
	}
	
	open var buildPhaseBaseTypeAsString: String {
		return "<Invalid, buildPhaseTypeAsString is abstract and should be overridden>"
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let n = name                                          {mySerialization["name"] = n}
		if let m = buildActionMask                               {mySerialization["buildActionMask"] = m.stringValue}
		if let b = runOnlyForDeploymentPostprocessing?.boolValue {mySerialization["runOnlyForDeploymentPostprocessing"] = b ? "1" : "0"}
		mySerialization["files"] = try files.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

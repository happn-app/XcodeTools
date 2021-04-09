import CoreData
import Foundation



@objc(PBXBuildPhase)
public class PBXBuildPhase : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		let mine = [
			"files_cd": "files"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		name = try rawObject.getIfExists("name")
		
		let filesIDs: [String] = try rawObject.get("files")
		files = try filesIDs.map{ try PBXBuildFile.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		if let buildActionMaskStr: String = try rawObject.getIfExists("buildActionMask") {
			guard let value = Int32(buildActionMaskStr) else {
				throw XcodeProjError(message: "Unexpected build action mask value \(buildActionMaskStr) in object \(xcID ?? "<unknown>")")
			}
			buildActionMask = NSNumber(value: value)
		}
		if let runOnlyForDeploymentPostprocessingStr: String = try rawObject.getIfExists("runOnlyForDeploymentPostprocessing") {
			guard let value = Int16(runOnlyForDeploymentPostprocessingStr) else {
				throw XcodeProjError(message: "Unexpected run only for deployment postprocessing value \(runOnlyForDeploymentPostprocessingStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for runOnlyForDeploymentPostprocessing \(runOnlyForDeploymentPostprocessingStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
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
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

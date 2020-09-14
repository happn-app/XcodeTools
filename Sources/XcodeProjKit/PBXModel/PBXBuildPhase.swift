import CoreData
import Foundation



@objc(PBXBuildPhase)
public class PBXBuildPhase : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
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
		
		name = try rawObjects.getIfExists("name")
		
		let filesIDs: [String] = try rawObject.get("files")
		files = try filesIDs.map{ try PBXBuildFile.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		if let buildActionMaskStr: String = try rawObject.getIfExists("buildActionMask") {
			guard let value = Int32(buildActionMaskStr) else {
				throw XcodeProjKitError(message: "Unexpected build action mask value \(buildActionMaskStr) in object \(xcID ?? "<unknown>")")
			}
			buildActionMask = NSNumber(value: value)
		}
		if let runOnlyForDeploymentPostprocessingStr: String = try rawObject.getIfExists("runOnlyForDeploymentPostprocessing") {
			guard let value = Int16(runOnlyForDeploymentPostprocessingStr) else {
				throw XcodeProjKitError(message: "Unexpected run only for deployment postprocessing value \(runOnlyForDeploymentPostprocessingStr)")
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
	
}

import CoreData
import Foundation



@objc(PBXCopyFilesBuildPhase)
public class PBXCopyFilesBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		dstPath = try rawObject.get("dstPath")
		
		do {
			let dstSubfolderSpecStr: String = try rawObject.get("dstSubfolderSpec")
			guard let value = Int16(dstSubfolderSpecStr) else {
				throw XcodeProjKitError(message: "Unexpected dst subfolder spec value \(dstSubfolderSpecStr)")
			}
			dstSubfolderSpec = value
		}
	}
	
	open override var buildPhaseBaseTypeAsString: String {
		return "CopyFiles" /* I guess… */
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["dstPath"] = try dstPath.get()
		mySerialization["dstSubfolderSpec"] = String(dstSubfolderSpec)
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

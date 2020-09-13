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
	
}

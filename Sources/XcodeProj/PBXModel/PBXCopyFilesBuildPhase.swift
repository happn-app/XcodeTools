import CoreData
import Foundation



@objc(PBXCopyFilesBuildPhase)
public class PBXCopyFilesBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		dstPath = try rawObject.getForParse("dstPath", xcID)
		
		dstSubfolderSpec = try rawObject.getInt16ForParse("dstSubfolderSpec", xcID)
	}
	
	open override var buildPhaseBaseTypeAsString: String {
		return "CopyFiles" /* I guess… */
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["dstPath"] = try dstPath.getForSerialization("dstPath", xcID)
		mySerialization["dstSubfolderSpec"] = String(dstSubfolderSpec)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

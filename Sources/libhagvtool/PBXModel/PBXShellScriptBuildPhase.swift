import CoreData
import Foundation



@objc(PBXShellScriptBuildPhase)
public class PBXShellScriptBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		inputPaths = try rawObject.get("inputPaths")
		inputFileListPaths = try rawObject.get("inputFileListPaths")
		
		outputPaths = try rawObject.get("outputPaths")
		outputFileListPaths = try rawObject.get("outputFileListPaths")
		
		shellPath = try rawObject.get("shellPath")
		shellScript = try rawObject.get("shellScript")
	}
	
}

import CoreData
import Foundation



@objc(PBXShellScriptBuildPhase)
public class PBXShellScriptBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		inputPaths = try rawObject.get("inputPaths")
		inputFileListPaths = try rawObject.getIfExists("inputFileListPaths")
		
		outputPaths = try rawObject.get("outputPaths")
		outputFileListPaths = try rawObject.getIfExists("outputFileListPaths")
		
		shellPath = try rawObject.get("shellPath")
		shellScript = try rawObject.get("shellScript")
		
		if let showEnvVarsInLogStr: String = try rawObject.getIfExists("showEnvVarsInLog") {
			guard let value = Int(showEnvVarsInLogStr) else {
				throw XcodeProjKitError(message: "Unexpected show env vars in log value \(showEnvVarsInLogStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Suspicious value for showEnvVarsInLog \(showEnvVarsInLogStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			showEnvVarsInLog = NSNumber(value: value != 0)
		}
	}
	
}

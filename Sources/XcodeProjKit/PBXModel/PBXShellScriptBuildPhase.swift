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
	
	open override var buildPhaseBaseTypeAsString: String {
		return "ShellScript" /* I guess… */
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let v = showEnvVarsInLog?.stringValue {mySerialization["showEnvVarsInLog"] = v}
		if let v = inputFileListPaths            {mySerialization["inputFileListPaths"] = v}
		if let v = outputFileListPaths           {mySerialization["outputFileListPaths"] = v}
		mySerialization["inputPaths"]          = try inputPaths.get()
		mySerialization["outputPaths"]         = try outputPaths.get()
		mySerialization["shellPath"]           = try shellPath.get()
		mySerialization["shellScript"]         = try shellScript.get()
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

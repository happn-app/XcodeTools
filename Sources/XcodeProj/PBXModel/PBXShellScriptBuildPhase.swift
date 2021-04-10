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
				throw XcodeProjError(message: "Unexpected show env vars in log value \(showEnvVarsInLogStr)")
			}
			if value != 0 && value != 1 {
				XcodeProjConfig.logger?.warning("Suspicious value for showEnvVarsInLog \(showEnvVarsInLogStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			showEnvVarsInLog = NSNumber(value: value != 0)
		}
		
		if let alwaysOutOfDateStr: String = try rawObject.getIfExists("alwaysOutOfDate") {
			guard let value = Int(alwaysOutOfDateStr) else {
				throw XcodeProjError(message: "Unexpected always out of date value \(alwaysOutOfDateStr)")
			}
			if value != 0 && value != 1 {
				XcodeProjConfig.logger?.warning("Suspicious value for alwaysOutOfDate \(alwaysOutOfDateStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			alwaysOutOfDate = NSNumber(value: value != 0)
		}
	}
	
	open override var buildPhaseBaseTypeAsString: String {
		return "ShellScript" /* I guess… */
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let v = showEnvVarsInLog?.boolValue {mySerialization["showEnvVarsInLog"] = v ? "1" : "0"}
		if let v = alwaysOutOfDate?.boolValue  {mySerialization["alwaysOutOfDate"] = v ? "1" : "0"}
		if let v = inputFileListPaths          {mySerialization["inputFileListPaths"] = v}
		if let v = outputFileListPaths         {mySerialization["outputFileListPaths"] = v}
		mySerialization["inputPaths"]  = try inputPaths.get()
		mySerialization["outputPaths"] = try outputPaths.get()
		mySerialization["shellPath"]   = try shellPath.get()
		mySerialization["shellScript"] = try shellScript.get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

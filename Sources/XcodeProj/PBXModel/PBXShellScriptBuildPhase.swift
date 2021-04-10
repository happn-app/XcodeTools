import CoreData
import Foundation



@objc(PBXShellScriptBuildPhase)
public class PBXShellScriptBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		inputPaths = try rawObject.getForParse("inputPaths", xcID)
		inputFileListPaths = try rawObject.getIfExistsForParse("inputFileListPaths", xcID)
		
		outputPaths = try rawObject.getForParse("outputPaths", xcID)
		outputFileListPaths = try rawObject.getIfExistsForParse("outputFileListPaths", xcID)
		
		shellPath = try rawObject.getForParse("shellPath", xcID)
		shellScript = try rawObject.getForParse("shellScript", xcID)
		
		showEnvVarsInLog = try rawObject.getBoolAsNumberIfExistsForParse("showEnvVarsInLog", xcID)
		alwaysOutOfDate = try rawObject.getBoolAsNumberIfExistsForParse("alwaysOutOfDate", xcID)
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
		mySerialization["inputPaths"]  = try inputPaths.getForSerialization("inputPaths", xcID)
		mySerialization["outputPaths"] = try outputPaths.getForSerialization("outputPaths", xcID)
		mySerialization["shellPath"]   = try shellPath.getForSerialization("shellPath", xcID)
		mySerialization["shellScript"] = try shellScript.getForSerialization("shellScript", xcID)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

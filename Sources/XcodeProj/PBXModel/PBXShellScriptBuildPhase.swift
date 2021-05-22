import CoreData
import Foundation



@objc(PBXShellScriptBuildPhase)
public class PBXShellScriptBuildPhase : PBXBuildPhase {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		inputPaths = try rawObject.getIfExistsForParse("inputPaths", xcID)
		inputFileListPaths = try rawObject.getIfExistsForParse("inputFileListPaths", xcID)
		
		outputPaths = try rawObject.getIfExistsForParse("outputPaths", xcID)
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
		if let v = inputPaths                  {mySerialization["inputPaths"] = v}
		if let v = outputPaths                 {mySerialization["outputPaths"] = v}
		if let v = inputFileListPaths          {mySerialization["inputFileListPaths"] = v}
		if let v = outputFileListPaths         {mySerialization["outputFileListPaths"] = v}
		mySerialization["shellPath"]   = try getShellPath()
		mySerialization["shellScript"] = try getShellScript()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
	public func getInputPaths()  throws -> [String] {try PBXObject.getNonOptionalValue(inputPaths,  "inputPaths",  xcID)}
	public func getOutputPaths() throws -> [String] {try PBXObject.getNonOptionalValue(outputPaths, "outputPaths", xcID)}
	public func getShellPath()   throws -> String   {try PBXObject.getNonOptionalValue(shellPath,   "shellPath",   xcID)}
	public func getShellScript() throws -> String   {try PBXObject.getNonOptionalValue(shellScript, "shellScript", xcID)}
	
}

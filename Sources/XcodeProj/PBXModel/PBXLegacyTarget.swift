import CoreData
import Foundation



/* From http://www.monobjc.net/xcode-project-file-format.html */
@objc(PBXLegacyTarget)
public class PBXLegacyTarget : PBXTarget {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		buildToolPath = try rawObject.get("buildToolPath")
		buildArgumentsString = try rawObject.get("buildArgumentsString")
		buildWorkingDirectory = try rawObject.get("buildWorkingDirectory")
		
		do {
		let passBuildSettingsInEnvironmentStr: String = try rawObject.get("passBuildSettingsInEnvironment")
			guard let value = Int16(passBuildSettingsInEnvironmentStr) else {
				throw XcodeProjError(message: "Unexpected pass build settings in environment value \(passBuildSettingsInEnvironmentStr)")
			}
			if value != 0 && value != 1 {
				XcodeProjConfig.logger?.warning("Unknown value for passBuildSettingsInEnvironment \(passBuildSettingsInEnvironmentStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			passBuildSettingsInEnvironment = (value != 0)
		}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["buildToolPath"]                  = try buildToolPath.get()
		mySerialization["buildArgumentsString"]           = try buildArgumentsString.get()
		mySerialization["buildWorkingDirectory"]          = try buildWorkingDirectory.get()
		mySerialization["passBuildSettingsInEnvironment"] = passBuildSettingsInEnvironment ? "1" : "0"
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

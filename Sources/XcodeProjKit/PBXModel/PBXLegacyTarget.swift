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
		
		if let passBuildSettingsInEnvironmentStr: String = try rawObject.getIfExists("passBuildSettingsInEnvironment") {
			guard let value = Int16(passBuildSettingsInEnvironmentStr) else {
				throw XcodeProjKitError(message: "Unexpected pass build settings in environment value \(passBuildSettingsInEnvironmentStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for passBuildSettingsInEnvironment \(passBuildSettingsInEnvironmentStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			passBuildSettingsInEnvironment = (value != 0)
		}
	}
	
}

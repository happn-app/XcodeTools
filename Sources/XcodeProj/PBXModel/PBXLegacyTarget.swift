import CoreData
import Foundation



/* From http://www.monobjc.net/xcode-project-file-format.html */
@objc(PBXLegacyTarget)
public class PBXLegacyTarget : PBXTarget {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		buildToolPath = try rawObject.getForParse("buildToolPath", xcID)
		buildArgumentsString = try rawObject.getForParse("buildArgumentsString", xcID)
		buildWorkingDirectory = try rawObject.getForParse("buildWorkingDirectory", xcID)
		
		passBuildSettingsInEnvironment = try rawObject.getBoolForParse("passBuildSettingsInEnvironment", xcID)
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["buildToolPath"]                  = try buildToolPath.getForSerialization("buildToolPath", xcID)
		mySerialization["buildArgumentsString"]           = try buildArgumentsString.getForSerialization("buildArgumentsString", xcID)
		mySerialization["buildWorkingDirectory"]          = try buildWorkingDirectory.getForSerialization("buildWorkingDirectory", xcID)
		mySerialization["passBuildSettingsInEnvironment"] = passBuildSettingsInEnvironment ? "1" : "0"
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

import CoreData
import Foundation



@objc(PBXBuildRule)
public class PBXBuildRule : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		fileType = try rawObject.getForParse("fileType", xcID)
		filePatterns = try rawObject.getForParse("filePatterns", xcID)
		compilerSpec = try rawObject.getForParse("compilerSpec", xcID)
		
		inputFiles = try rawObject.getForParse("inputFiles", xcID)
		outputFiles = try rawObject.getForParse("outputFiles", xcID)
		
		script = try rawObject.getForParse("script", xcID)
		
		isEditable = try rawObject.getBoolForParse("isEditable", xcID)
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["fileType"]     = try fileType.getForSerialization("fileType", xcID)
		mySerialization["filePatterns"] = try filePatterns.getForSerialization("filePatterns", xcID)
		mySerialization["compilerSpec"] = try compilerSpec.getForSerialization("compilerSpec", xcID)
		mySerialization["inputFiles"]   = try inputFiles.getForSerialization("inputFiles", xcID)
		mySerialization["outputFiles"]  = try outputFiles.getForSerialization("outputFiles", xcID)
		mySerialization["script"]       = try script.getForSerialization("script", xcID)
		mySerialization["isEditable"]   = isEditable ? "1" : "0"
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

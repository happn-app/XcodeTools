import CoreData
import Foundation



@objc(PBXBuildRule)
public class PBXBuildRule : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		fileType = try rawObject.get("fileType")
		filePatterns = try rawObject.get("filePatterns")
		compilerSpec = try rawObject.get("compilerSpec")
		
		inputFiles = try rawObject.get("inputFiles")
		outputFiles = try rawObject.get("outputFiles")
		
		script = try rawObject.get("script")
		
		do {
			let isEditableStr: String = try rawObject.get("isEditable")
			guard let value = Int(isEditableStr) else {
				throw XcodeProjError(message: "Unexpected is editable value \(isEditableStr) in object \(xcID ?? "<unknown>")")
			}
			if value != 0 && value != 1 {
				XcodeProjConfig.logger?.warning("Suspicious value for isEditable \(isEditableStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			isEditable = (value != 0)
		}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["fileType"]     = try fileType.get()
		mySerialization["filePatterns"] = try filePatterns.get()
		mySerialization["compilerSpec"] = try compilerSpec.get()
		mySerialization["inputFiles"]   = try inputFiles.get()
		mySerialization["outputFiles"]  = try outputFiles.get()
		mySerialization["script"]       = try script.get()
		mySerialization["isEditable"]   = isEditable ? "1" : "0"
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

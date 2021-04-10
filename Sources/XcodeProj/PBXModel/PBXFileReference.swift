import CoreData
import Foundation



@objc(PBXFileReference)
public class PBXFileReference : PBXFileElement {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		fileEncoding = try rawObject.getInt16AsNumberIfExistsForParse("fileEncoding", xcID)
		lineEnding = try rawObject.getInt16AsNumberIfExistsForParse("lineEnding", xcID)
		includeInIndex = try rawObject.getBoolAsNumberIfExistsForParse("includeInIndex", xcID)
		explicitFileType = try rawObject.getIfExistsForParse("explicitFileType", xcID)
		lastKnownFileType = try rawObject.getIfExistsForParse("lastKnownFileType", xcID)
		xcLanguageSpecificationIdentifier = try rawObject.getIfExistsForParse("xcLanguageSpecificationIdentifier", xcID)
		plistStructureDefinitionIdentifier = try rawObject.getIfExistsForParse("plistStructureDefinitionIdentifier", xcID)
	}
	
	open override var oneLineStringSerialization: Bool {
		return true
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let v = fileEncoding?.stringValue          {mySerialization["fileEncoding"] = v}
		if let v = lineEnding?.stringValue            {mySerialization["lineEnding"] = v}
		if let b = includeInIndex?.boolValue          {mySerialization["includeInIndex"] = b ? "1" : "0"}
		if let v = explicitFileType                   {mySerialization["explicitFileType"] = v}
		if let v = lastKnownFileType                  {mySerialization["lastKnownFileType"] = v}
		if let v = xcLanguageSpecificationIdentifier  {mySerialization["xcLanguageSpecificationIdentifier"] = v}
		if let v = plistStructureDefinitionIdentifier {mySerialization["plistStructureDefinitionIdentifier"] = v}
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
	public override var parent: PBXFileElement? {
		assert(
			(group_ != nil && variantGroup_ == nil && versionGroup_ == nil) ||
			(group_ == nil && variantGroup_ != nil && versionGroup_ == nil) ||
			(group_ == nil && variantGroup_ == nil && versionGroup_ != nil) ||
			(group_ == nil && variantGroup_ == nil && versionGroup_ == nil)
		)
		return group_ ?? variantGroup_ ?? versionGroup_
	}
	
}

import CoreData
import Foundation



@objc(PBXFileReference)
public class PBXFileReference : PBXFileElement {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		if let fileEncodingStr: String = try rawObject.getIfExists("fileEncoding") {
			guard let value = Int16(fileEncodingStr) else {
				throw XcodeProjKitError(message: "Unexpected file encoding value \(fileEncodingStr)")
			}
			fileEncoding = NSNumber(value: value)
		}
		if let lineEndingStr: String = try rawObject.getIfExists("lineEnding") {
			guard let value = Int16(lineEndingStr) else {
				throw XcodeProjKitError(message: "Unexpected line ending value \(lineEndingStr)")
			}
			lineEnding = NSNumber(value: value)
		}
		if let includeInIndexStr: String = try rawObject.getIfExists("includeInIndex") {
			guard let value = Int(includeInIndexStr) else {
				throw XcodeProjKitError(message: "Unexpected include in index value \(includeInIndexStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Suspicious value for includeInIndex \(includeInIndexStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			includeInIndex = NSNumber(value: value != 0)
		}
		explicitFileType = try rawObject.getIfExists("explicitFileType")
		lastKnownFileType = try rawObject.getIfExists("lastKnownFileType")
		xcLanguageSpecificationIdentifier = try rawObject.getIfExists("xcLanguageSpecificationIdentifier")
		plistStructureDefinitionIdentifier = try rawObject.getIfExists("plistStructureDefinitionIdentifier")
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
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
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

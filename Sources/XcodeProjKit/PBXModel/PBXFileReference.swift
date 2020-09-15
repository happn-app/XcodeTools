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
	
}

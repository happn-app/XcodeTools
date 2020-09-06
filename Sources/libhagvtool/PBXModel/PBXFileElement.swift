import CoreData
import Foundation



/* From http://www.monobjc.net/xcode-project-file-format.html */
@objc(PBXFileElement)
public class PBXFileElement : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		sourceTree = try rawObject.get("sourceTree")
		name = try rawObject.getIfExists("name")
		path = try rawObject.getIfExists("path")
		
		if let indentWidthStr: String = try rawObject.getIfExists("indentWidth") {
			guard let value = Int16(indentWidthStr) else {
				throw HagvtoolError(message: "Unexpected indent width value \(indentWidthStr) in object \(id ?? "<unknown>")")
			}
			indentWidth = NSNumber(value: value)
		}
		if let tabWidthStr: String = try rawObject.getIfExists("tabWidth") {
			guard let value = Int16(tabWidthStr) else {
				throw HagvtoolError(message: "Unexpected tab width value \(tabWidthStr) in object \(id ?? "<unknown>")")
			}
			tabWidth = NSNumber(value: value)
		}
		if let usesTabsStr: String = try rawObject.getIfExists("usesTabs") {
			guard let value = Int16(usesTabsStr) else {
				throw HagvtoolError(message: "Unexpected uses tabs value \(usesTabsStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for usesTabs \(usesTabsStr) in object \(id ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			usesTabs = NSNumber(value: value != 0)
		}
		if let wrapsLinesStr: String = try rawObject.getIfExists("wrapsLines") {
			guard let value = Int16(wrapsLinesStr) else {
				throw HagvtoolError(message: "Unexpected wraps lines value \(wrapsLinesStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Unknown value for wrapsLines \(wrapsLinesStr) in object \(id ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			wrapsLines = NSNumber(value: value != 0)
		}
	}
	
}

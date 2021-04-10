import CoreData
import Foundation

import Utils



extension Dictionary where Key == String {
	
	func getForParse<T>(_ key: Key, _ objectID: String?) throws -> T {
		return try get(
			key,
			notFoundError: XcodeProjError.parseError(.missingProperty(propertyName: key), objectID: objectID),
			wrongTypeError: XcodeProjError.parseError(.unexpectedPropertyValueType(propertyName: key, value: self[key]!), objectID: objectID)
		)
	}
	
	func getIfExistsForParse<T>(_ key: Key, _ objectID: String?) throws -> T? {
		return try getIfExists(
			key,
			wrongTypeError: XcodeProjError.parseError(.unexpectedPropertyValueType(propertyName: key, value: self[key]!), objectID: objectID)
		)
	}
	
	func getURLForParse(_ key: Key, _ objectID: String?) throws -> URL {
		let v: String = try getForParse(key, objectID)
		guard let url = URL(string: v) else {
			throw XcodeProjError.parseError(.invalidURLString(propertyName: key, string: v), objectID: objectID)
		}
		return url
	}
	
	func getIntForParse(_ key: Key, _ objectID: String?) throws -> Int {
		let v: String = try getForParse(key, objectID)
		guard let i = Int(v) else {
			throw XcodeProjError.parseError(.invalidIntString(propertyName: key, string: v), objectID: objectID)
		}
		return i
	}
	
	func getInt16ForParse(_ key: Key, _ objectID: String?) throws -> Int16 {
		let v: String = try getForParse(key, objectID)
		guard let i = Int16(v) else {
			throw XcodeProjError.parseError(.invalidIntString(propertyName: key, string: v), objectID: objectID)
		}
		return i
	}
	
	func getBoolForParse(_ key: Key, _ objectID: String?) throws -> Bool {
		let i = try getIntForParse(key, objectID)
		if i != 0 && i != 1 {
			XcodeProjConfig.logger?.warning("Suspicious value “\(i)” for key “\(key)” in object “\(objectID ?? "<unknown or root>")”; expecting 0 or 1; setting to true.")
		}
		return i != 0
	}
	
	func getIntIfExistsForParse(_ key: Key, _ objectID: String?) throws -> Int? {
		guard let v: String = try getIfExistsForParse(key, objectID) else {return nil}
		guard let i = Int(v) else {
			throw XcodeProjError.parseError(.invalidIntString(propertyName: key, string: v), objectID: objectID)
		}
		return i
	}
	
	func getBoolAsNumberIfExistsForParse(_ key: Key, _ objectID: String?) throws -> NSNumber? {
		guard let i = try getIntIfExistsForParse(key, objectID) else {return nil}
		if i != 0 && i != 1 {
			XcodeProjConfig.logger?.warning("Suspicious value “\(i)” for key “\(key)” in object “\(objectID ?? "<unknown or root>")”; expecting 0 or 1; setting to true.")
		}
		return NSNumber(value: i != 0)
	}
	
	func getIntAsNumberIfExistsForParse(_ key: Key, _ objectID: String?) throws -> NSNumber? {
		guard let i = try getIntIfExistsForParse(key, objectID) else {return nil}
		return NSNumber(value: i)
	}
	
	func getInt32AsNumberIfExistsForParse(_ key: Key, _ objectID: String?) throws -> NSNumber? {
		guard let v: String = try getIfExistsForParse(key, objectID) else {return nil}
		guard let i = Int32(v) else {
			throw XcodeProjError.parseError(.invalidIntString(propertyName: key, string: v), objectID: objectID)
		}
		return NSNumber(value: i)
	}
	
	func getInt16AsNumberIfExistsForParse(_ key: Key, _ objectID: String?) throws -> NSNumber? {
		guard let v: String = try getIfExistsForParse(key, objectID) else {return nil}
		guard let i = Int16(v) else {
			throw XcodeProjError.parseError(.invalidIntString(propertyName: key, string: v), objectID: objectID)
		}
		return NSNumber(value: i)
	}
	
}


extension Optional {
	
	func getForSerialization(_ propretyName: String, _ objectID: String?) throws -> Wrapped {
		return try get(orThrow: XcodeProjError.invalidObjectGraph(.missingProperty(propertyName: propretyName), objectID: objectID))
	}
	
}


extension PBXObject {
	
	func getIDAndCommentForSerialization(_ propretyName: String, _ objectID: String?, projectName: String) throws -> ValueAndComment {
		return try xcIDAndComment(projectName: projectName).getForSerialization("\(propretyName).xcIDAndComment", objectID)
	}
	
}


extension Optional where Wrapped : PBXObject {
	
	func getIDAndCommentForSerialization(_ propretyName: String, _ objectID: String?, projectName: String) throws -> ValueAndComment {
		return try getForSerialization(propretyName, objectID).getIDAndCommentForSerialization(propretyName, objectID, projectName: projectName)
	}
	
}


/* Apparently, this ain’t possible, sadly. So we do the variant that comes next,
 * and call getForSerialization on the resulting optional value. */
//extension Optional where Wrapped : Array<PBXObject> {
//
//	func getIDsAndCommentsForSerialization(_ propretyName: String, _ objectID: String?, projectName: String) throws -> [ValueAndComment] {
//		return try getForSerialization(propretyName, objectID)
//			.enumerated()
//			.map{ try $0.element.xcIDAndComment(projectName: projectName).getForSerialization("\(propretyName)[\($0.offset)].xcIDAndComment", objectID) }
//	}
//
//}
extension Array where Element : PBXObject {
	
	func getIDsAndCommentsForSerialization(_ propretyName: String, _ objectID: String?, projectName: String) throws -> [ValueAndComment] {
		return try enumerated().map{ try $0.element.xcIDAndComment(projectName: projectName).getForSerialization("\(propretyName)[\($0.offset)].xcIDAndComment", objectID) }
	}
	
}


extension String {
	
	/** Not optimized! Returns the prefix. */
	mutating func removePrefix(from characterSet: CharacterSet) -> String {
		var ret = ""
		while let prefixRange = rangeOfCharacter(from: characterSet, options: [.literal, .anchored]) {
			ret += self[prefixRange]
			removeSubrange(prefixRange)
		}
		return ret
	}
	
	/** Not optimized! Returns the suffix. */
	mutating func removeSuffix(from characterSet: CharacterSet) -> String {
		var ret = ""
		while let suffixRange = rangeOfCharacter(from: characterSet, options: [.literal, .anchored, .backwards]) {
			ret = self[suffixRange] + ret
			removeSubrange(suffixRange)
		}
		return ret
	}
	
	/* From https://opensource.apple.com/source/CF/CF-1153.18/CFOldStylePList.c
	 *    #define isValidUnquotedStringCharacter(x) (((x) >= 'a' && (x) <= 'z') || ((x) >= 'A' && (x) <= 'Z') || ((x) >= '0' && (x) <= '9') || (x) == '_' || (x) == '$' || (x) == '/' || (x) == ':' || (x) == '.' || (x) == '-')
	 *
	 * We _infer_ that escaped chars are \n, \t, ", \ and that’s all, but we’re
	 * not 100% certain. We only tested different values to infer this; we did
	 * not test all possible characters. */
	func escapedForPBXProjValue() -> String {
		guard !isEmpty else {
			return "\"\""
		}
		
		/* The dash and colon should be there. They aren’t for Xcode apparently. */
		let validUnquotedStringChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$/.")
		/* The triple underscore, I only got the prefix rule, the double slash, I
		 * didn’t get at all. Corrections from https://github.com/tuist/XcodeProj/blob/master/Sources/XcodeProj/Utils/CommentedString.swift */
		if rangeOfCharacter(from: validUnquotedStringChars.inverted) == nil && !contains("___") && !contains("//") {
			return self
		}
		
		/* We found this… */
		let escapeTabsAndNewlines = (utf16.count > 5)
		
		var escaped = self
			.replacingOccurrences(of: "\\", with: "\\\\", options: .literal)
			.replacingOccurrences(of: "\"", with: "\\\"", options: .literal)
		if escapeTabsAndNewlines {
			escaped = escaped
				.replacingOccurrences(of: "\n", with: "\\n",  options: .literal)
				.replacingOccurrences(of: "\t", with: "\\t",  options: .literal)
		}
		return "\"" + escaped + "\""
	}
	
}


public extension NSManagedObjectContext {
	
	/* Should be declared as rethrows instead of throws, but did not find a way
	 * to do it sadly. */
	func performAndWait<T>(_ block: () throws -> T) throws -> T {
		var ret: T?
		var err: Error?
		performAndWait{
			do    {ret = try block()}
			catch {err = error}
		}
		if let e = err {throw e}
		return ret!
	}
	
}


extension NSEntityDescription {
	
	func topmostSuperentity() -> NSEntityDescription {
		if let s = superentity {
			return s.topmostSuperentity()
		}
		return self
	}
	
}

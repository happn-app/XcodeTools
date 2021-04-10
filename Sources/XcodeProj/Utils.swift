import CoreData
import Foundation



extension Dictionary where Value : Equatable {
	
	/**
	Same as `merging(_:, uniquingKeysWith:)`, but other dictionary must be fully
	distinct from client (set of keys is distinct) or value must be the same for
	the same keys, otherwise you get a crash.
	
	- Note: Requires `Value` of the `Dictionary` to be `Equatable` only to be
	able to check if values are equal in case of same key in two dictionaries. */
	func mergingUnambiguous(_ other: [Key: Value]) -> [Key: Value] {
		return merging(other, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			return current
		})
	}
	
}

extension Dictionary {
	
	func get<T>(_ key: Key) throws -> T {
		guard let e = self[key] else {
			throw XcodeProjError(message: "Value not found for key \(key)")
		}
		guard let t = e as? T else {
			throw XcodeProjError(message: "Value does not have correct type for key \(key)")
		}
		return t
	}
	
	func getIfExists<T>(_ key: Key) throws -> T? {
		guard let e = self[key] else {
			return nil
		}
		guard let t = e as? T else {
			throw XcodeProjError(message: "Value does not have correct type for key \(key)")
		}
		return t
	}
	
}


extension Optional {
	
	func get(nilError: Error = XcodeProjError(message: "Trying to get value of nil optional")) throws -> Wrapped {
		guard let v = self else {
			throw nilError
		}
		return v
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

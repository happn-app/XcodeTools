/*
 * utils.swift
 * hagvtool
 *
 * Created by François Lamboley on 12/15/16.
 * Copyright © 2016 happn. All rights reserved.
 */

import Foundation



extension String {
	
	func safeString(forChars safeChars: Character...) -> String {
		assert(!safeChars.contains("\\"))
		var res = replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
		for char in safeChars {
			res = res.replacingOccurrences(of: String(char), with: "\\\(char)")
		}
		return res
	}
	
}



/** Returns: `nil` in case of failure */
func insertOrUpdate(buildSetting: String, withValue value: String, parsedBuildSettings: [String: Any], inBuildConfigString buildConfigStr: String) throws -> String {
	var buildConfigStr = buildConfigStr as NSString
	let buildConfigStrRange = NSRange(location: 0, length: buildConfigStr.length)
	
	let expr = try! NSRegularExpression(pattern: "^(\\s*\(NSRegularExpression.escapedPattern(for: buildSetting))\\s*=\\s*)\"?.*\"?(\\s*;)$", options: .anchorsMatchLines)
	let nMatches = expr.numberOfMatches(in: buildConfigStr as String, options: [], range: buildConfigStrRange)
	guard nMatches <= 1 else {
		print("Found too many matches for build setting \(buildSetting) in build config \(buildConfigStr)", to: &mx_stderr)
		throw NSError()
	}
	if nMatches == 1 {
		buildConfigStr = expr.stringByReplacingMatches(in: buildConfigStr as String, options: [], range: buildConfigStrRange, withTemplate: "$1\(value)$2") as NSString
	} else {
		let sortedExistingKeys = parsedBuildSettings.keys.filter{ $0 <= buildSetting }.sorted()
		
		let indentPlusOne: Bool
		let expr: NSRegularExpression
		if let setting = sortedExistingKeys.last {
			indentPlusOne = false
			expr = try! NSRegularExpression(pattern: "^(\\s*)\"?\(NSRegularExpression.escapedPattern(for: setting))\"?.*=.*;$", options: .anchorsMatchLines)
		} else {
			indentPlusOne = true
			expr = try! NSRegularExpression(pattern: "^(\\s*)buildSettings.*=.*\\{$", options: .anchorsMatchLines)
		}
		let matches = expr.matches(in: buildConfigStr as String, options: [], range: buildConfigStrRange)
		guard matches.count == 1 else {
			print("Found 0 or too many matches matching previous line for build setting insertion. Previous line is searched with regexp \(expr)", to: &mx_stderr)
			throw NSError()
		}
		let match = matches[0] /* [0] as opposed to .first!... */
		let indent = expr.replacementString(for: match, in: buildConfigStr as String, offset: 0, template: "$1") + (indentPlusOne ? "\t" /* We "know..." */ : "" /* We could check the indent of a setting we know is there instead of guessing for \t as indents, but... yeah. */)
		let r = match.range
		let replacedRange = NSRange(location: r.location + r.length, length: 0)
		/* Sometimes a double quote should be needed around the build setting
		 * we're adding. In none of the cases we'll use, so... yeah. */
		buildConfigStr = buildConfigStr.replacingCharacters(in: replacedRange, with: "\n\(indent)\(buildSetting) = \(value);") as NSString
	}
	return buildConfigStr as String
}


class StandardErrorOutputStream: TextOutputStream {
	
	func write(_ string: String) {
		let stderr = FileHandle.standardError
		stderr.write(string.data(using: String.Encoding.utf8)!)
	}
	
}

class StandardOutputStream: TextOutputStream {
	
	func write(_ string: String) {
		let stderr = FileHandle.standardOutput
		stderr.write(string.data(using: String.Encoding.utf8)!)
	}
	
}

var mx_stdout = StandardOutputStream()
var mx_stderr = StandardErrorOutputStream()

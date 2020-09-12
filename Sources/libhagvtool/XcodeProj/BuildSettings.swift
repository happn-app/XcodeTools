import Foundation



/**
Represents a “level” of build settings.

This can either be an xcconfig file, or the project settings, or the settings of
a target.*/
public struct BuildSettings {
	
	public var settings: [BuildSetting]
	
	public init(rawBuildSettings: [String: Any], allowCommaSeparatorForParameters: Bool = false) {
		var result = [BuildSetting]()
		for (keyAndParameters, value) in rawBuildSettings {
			let scanner = Scanner(string: keyAndParameters)
			let key = scanner.scanUpToString("[") ?? ""
			let parameters = BuildSettings.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
			if !scanner.isAtEnd {
				NSLog("%@", "Warning: Found build setting which seems invalid (scanner not at end after parsing parameters). Raw key is: “\(keyAndParameters)”.")
			}
			result.append(BuildSetting(key: key, value: value, parameters: parameters))
		}
		settings = result
	}
	
	public init(xcconfigURL url: URL, failIfFileDoesNotExist: Bool = true, seenFiles: Set<URL> = [], allowCommaSeparatorForParameters: Bool = false) throws {
//		NSLog("%@", "Trying to parse xcconfig file \(url.absoluteString)")
		
		var isDir = ObjCBool(false)
		if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
			if failIfFileDoesNotExist {
				throw HagvtoolError(message: "Cannot find xcconfig file at URL \(url.absoluteString)")
			} else {
				settings = []
				return
			}
		}
		if isDir.boolValue {
			/* We silently fail if the xcconfig file is a directory! This is the
			 * observed behaviour in Xcode. */
			settings = []
			return
		}
		
		let seenFiles = seenFiles.union([url.absoluteURL])
		let fileContents = try String(contentsOf: url)
		
		/* We spcifically want space and tabs; other unicode whitespaces are not
		 * valid for our use case. */
		let xcconfigWhitespace = CharacterSet(charactersIn: " \t")
		let firstCharVar = CharacterSet(charactersIn: "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
		let otherVarChars = firstCharVar.union(CharacterSet(charactersIn: "0123456789"))
		
		var error: Error?
		var result = [BuildSetting]()
		fileContents.enumerateLines{ line, stop in
			do {
				let line = line.components(separatedBy: "//").first!.trimmingCharacters(in: xcconfigWhitespace)
				guard !line.isEmpty else {return}
				
				let scanner = Scanner(string: line)
				if scanner.scanString("#") != nil {
					/* We have a preprocessor directive line. */
					let directive = scanner.scanUpToCharacters(from: xcconfigWhitespace.union(CharacterSet(charactersIn: "?")))
					let isOptional = (scanner.scanString("?") != nil)
					switch directive {
						case "include"?:
							_ = scanner.scanCharacters(from: xcconfigWhitespace)
							guard scanner.scanString("\"") != nil else {
								throw HagvtoolError(message: "Expected a double-quote after include directive in xcconfig file \(url).")
							}
							guard let filename = scanner.scanUpToString("\"") else {
								throw HagvtoolError(message: "Cannot parse include directive filename in xcconfig file \(url).")
							}
							_ = scanner.scanString("\"")
							guard scanner.isAtEnd else {
								throw HagvtoolError(message: "Unexpected characters after include directive in xcconfig file \(url).")
							}
							
							#warning("TODO: The case of <DEVELOPER_DIR>")
							/* If filename starts with <DEVELOPER_DIR>, the include is
							 * relative to the developer dir, says https://pewpewthespells.com/blog/xcconfig_guide.html
							 * (I have tested, it is true).
							 * Question: Is it possible to user other <VARIABLES>?
							 * Other question: Can <> be used if not prefix of path? */
							
							let urlToImport = URL(fileURLWithPath: filename, isDirectory: false, relativeTo: url)
							if !seenFiles.contains(urlToImport.absoluteURL) {
								let importedSettings = try BuildSettings(xcconfigURL: urlToImport, failIfFileDoesNotExist: !isOptional, seenFiles: seenFiles)
								result.append(contentsOf: importedSettings.settings)
							} else {
								NSLog("%@", "Warning: Skipping include of \(urlToImport.absoluteString) to avoid cycling dependency from \(url.absoluteString).")
							}
							
						default:
							throw HagvtoolError(message: "Unknown directive “\(directive ?? "<nil>")” in xcconfig file \(url).")
					}
				} else {
					/* We should have a normal line (setting = value) */
					let variableName: String
					do {
						guard let firstChar = scanner.scanCharacter() else {
							throw HagvtoolError(message: "Internal error in \(#file), first char of line is nil, but line should not be empty.")
						}
						guard let scalar = firstChar.unicodeScalars.first, firstChar.unicodeScalars.count == 1, firstCharVar.contains(scalar) else {
							throw HagvtoolError(message: "Invalid first char for a variable in xcconfig \(url.absoluteString).")
						}
						let restOfVariableName = scanner.scanCharacters(from: otherVarChars) ?? ""
						variableName = String(firstChar) + restOfVariableName
					}
					
					let parameters = BuildSettings.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
					
					_ = scanner.scanCharacters(from: xcconfigWhitespace)
					guard scanner.scanString("=") != nil else {
						throw HagvtoolError(message: "Unexpected character after variable name in xcconfig \(url.absoluteString).")
					}
					
					let value: String
					do {
						let rawValue = scanner.scanUpToCharacters(from: CharacterSet()) ?? "" /* Scan to the end of string. */
						let trimmed = rawValue.trimmingCharacters(in: xcconfigWhitespace)
						if trimmed.last == ";" {value = String(trimmed[trimmed.startIndex..<trimmed.index(before: trimmed.endIndex)]).trimmingCharacters(in: xcconfigWhitespace)}
						else                   {value = trimmed}
					}
					
					result.append(BuildSetting(key: variableName, value: value, parameters: parameters))
				}
			} catch let e {
				stop = true
				error = e
			}
		}
		if let e = error {throw e}
		
		settings = result
	}
	
	/**
	Parses the parameter of a setting.
	
	Expects a scanner whose location is at the beginning of the parameters
	(open bracket). Example:
	```
	MY_BUILD_SETTING[skd=*]
	                ^ scanner location
	```
	
	At the end of the function, the scanner’s location will be at the end of the
	parameters (just after the closing bracket). Example:
	```
	MY_BUILD_SETTING[skd=*]
	                       ^ scanner location
	```
	
	In case of a parsing error, the scanner’s location will be put to the last
	successful parse location, and all successfully parsed parameters will be
	returned. Examples:
	```
	MY_BUILD_SETTING[skd=*][this_is_junk
	                       ^ scanner location
	   -> Returned parameters: [("sdk", "*")]
	MY_BUILD_SETTING[skd=*][arch=*,this_is_junk
	                       ^ scanner location
	   -> Returned parameters: [("sdk", "*")]
	```
	
	- parameter scanner: A scanner whose location is at the beginning of the
	parameters.
	- parameter allowCommaSeparator:
	https://pewpewthespells.com/blog/xcconfig_guide.html says the settings
	parameters can be separated by a comma, like so: `PARAMETER[sdk=*,arch=*]`,
	however my tests told me it does not work! (Xcode 12.0 beta 6 (12A8189n))
	You can reactivate parsing w/ the comma for tests if needed w/ this param. */
	private static func parseSettingParams(scanner: Scanner, allowCommaSeparator: Bool) -> [(key: String, value: String)] {
		var first = true
		var success = true
		var lastSuccessParseIdx = scanner.currentIndex
		var parameters = [(key: String, value: String)]()
		var pendingParameters = [(key: String, value: String)]()
		while scanner.scanString("[") != nil || (allowCommaSeparator && !first && scanner.scanString(",") != nil) {
			let variantName = scanner.scanUpToString("=") ?? ""
			if scanner.scanString("=") == nil {
				scanner.currentIndex = lastSuccessParseIdx
				return parameters
			}
			
			let variantValue = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: allowCommaSeparator ? ",]" : "]")) ?? ""
			if scanner.scanString("]") != nil {
				parameters.append(contentsOf: pendingParameters)
				parameters.append((variantName, variantValue))
				lastSuccessParseIdx = scanner.currentIndex
				pendingParameters.removeAll()
				success = true
			} else {
				/* We are either on the comma separator (if allowed) or at the end
				 * of the string. If at the end of the string, this is an error,
				 * which will be caugth when we exit the loop and success is not
				 * true. If we’re on the comma separator, we continue the parsing. */
				pendingParameters.append((variantName, variantValue))
				success = false
			}
			
			first = false
		}
		if !success {
			scanner.currentIndex = lastSuccessParseIdx
		}
		return parameters
	}
	
}

import Foundation



public struct XCConfig {
	
	public enum Line {
		
		public enum LineParsingError : Error {
			
			case unknownDirective(String)
			case gotSpaceAfterSharpInDirective
			case expectedDoubleQuoteAfterIncludeDirective
			case cannotParseIncludePath
			case unexpectedCharAfterInclude
			
			case invalidFirstCharInVar(Character)
			case unexpectedCharAfterVarName
			
		}
		
		case void(String)
		case include(path: String, isOptional: Bool, prefix: String, postSharp: String, postDirective: String, suffix: String)
		case value(key: BuildSettingKey, value: String, prefix: String, equalSign: String, suffix: String)
		
		init(lineString line: String, allowCommaSeparatorForParameters: Bool = false, allowSpacesAfterSharp: Bool = false) throws {
			/* We specifically want space and tabs; other unicode whitespaces are
			 * not valid for our use case. */
			let xcconfigWhitespace = CharacterSet(charactersIn: " \t")
			
			let lineContent, linePrefix, lineSuffix: String
			do {
				let components = line.components(separatedBy: "//")
				var lineContentBuilding = components.first!
				
				let lineCommentComponents = components[components.index(after: components.startIndex)..<components.endIndex]
				let lineComment: String
				if !lineCommentComponents.isEmpty {lineComment = "//" + lineCommentComponents.joined(separator: "//")}
				else                              {lineComment = ""}
				
				linePrefix = lineContentBuilding.removePrefix(from: xcconfigWhitespace)
				let preCommentLineSuffix = lineContentBuilding.removeSuffix(from: xcconfigWhitespace)
				
				lineContent = lineContentBuilding
				lineSuffix = preCommentLineSuffix + lineComment
			}
			assert(line == linePrefix + lineContent + lineSuffix)
			guard !lineContent.isEmpty else {
				self = .void(line)
				return
			}
			
			let scanner = Scanner(forParsing: lineContent)
			if scanner.scanString("#") != nil {
				/* We have a preprocessor directive line. */
				let postSharp = scanner.scanCharacters(from: xcconfigWhitespace) ?? ""
				/* It seems the xcconfig parser is not the same when compiling and
				 * in Xcode build settings UI.
				 * In the UI, the spaces after the sharp seem to break the xcconfig
				 * file fully; in code, the directive seems to work ok w/ spaces! */
				guard postSharp.isEmpty || allowSpacesAfterSharp else {throw LineParsingError.gotSpaceAfterSharpInDirective}
				
				let directive = scanner.scanUpToCharacters(from: xcconfigWhitespace.union(CharacterSet(charactersIn: "?"))) ?? ""
				let isOptional = (scanner.scanString("?") != nil)
				let postDirective = scanner.scanCharacters(from: xcconfigWhitespace) ?? ""
				switch directive {
					case "include":
						guard scanner.scanString("\"") != nil else {
							throw LineParsingError.expectedDoubleQuoteAfterIncludeDirective
						}
						guard let path = scanner.scanUpToString("\"") else {
							throw LineParsingError.cannotParseIncludePath
						}
						_ = scanner.scanString("\"")
						guard scanner.isAtEnd else {
							throw LineParsingError.unexpectedCharAfterInclude
						}
						
						self = .include(path: path, isOptional: isOptional, prefix: linePrefix, postSharp: postSharp, postDirective: postDirective, suffix: lineSuffix)
						
					default:
						throw LineParsingError.unknownDirective(directive)
				}
			} else {
				/* We should have a normal line (setting = value) */
				let variableName: String
				do {
					guard let firstChar = scanner.scanCharacter() else {
						throw XcodeProjKitError(message: "Internal error in \(#file), first char of line is nil, but line should not be empty.")
					}
					guard let scalar = firstChar.unicodeScalars.first, firstChar.unicodeScalars.count == 1, BuildSettings.charactersValidForFirstVariableCharacter.contains(scalar) else {
						throw LineParsingError.invalidFirstCharInVar(firstChar)
					}
					let restOfVariableName = scanner.scanCharacters(from: BuildSettings.charactersValidInVariableName) ?? ""
					variableName = String(firstChar) + restOfVariableName
				}
				
				let parameters = BuildSettingKey.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
				
				let beforeEqualSign = scanner.scanCharacters(from: xcconfigWhitespace) ?? ""
				guard scanner.scanString("=") != nil else {
					throw LineParsingError.unexpectedCharAfterVarName
				}
				
				let value: String
				let afterEqualSign, postVarSuffix: String
				do {
					var valueBuilding = scanner.scanUpToCharacters(from: CharacterSet()) ?? "" /* Scan to the end of string. */
					
					/* Find and trim the value prefix (whitespaces) */
					afterEqualSign = valueBuilding.removePrefix(from: xcconfigWhitespace)
					
					/* Find and trim the value suffix (whitespaces + ";") */
					if valueBuilding.last == ";" {
						valueBuilding = String(valueBuilding[valueBuilding.startIndex..<valueBuilding.index(before: valueBuilding.endIndex)])
						postVarSuffix = valueBuilding.removeSuffix(from: xcconfigWhitespace) + ";"
					} else {
						postVarSuffix = ""
					}
					
					value = valueBuilding
				}
				
				self = .value(
					key: BuildSettingKey(key: variableName, parameters: parameters),
					value: value,
					prefix: linePrefix,
					equalSign: beforeEqualSign + "=" + afterEqualSign,
					suffix: postVarSuffix + lineSuffix
				)
			}
		}
		
		var lineString: String {
			switch self {
				case .void(let str):
					return str
					
				case .include(path: let path, isOptional: let optional, prefix: let prefix, postSharp: let postSharp, postDirective: let postDirective, suffix: let suffix):
					return prefix + "#" + postSharp + "include" + (optional ? "?" : "") + postDirective + "\"" + path + "\"" + suffix
					
				case .value(key: let key, value: let value, prefix: let prefix, equalSign: let equalSign, suffix: let suffix):
					return prefix + key.serialized + equalSign + value + suffix
			}
		}
		
	}
	
	public var sourceURL: URL
	public var lines: [Line]
	
	public init(url: URL, failIfFileDoesNotExist: Bool = true, allowCommaSeparatorForParameters: Bool = false, allowSpacesAfterSharp: Bool = false) throws {
//		NSLog("%@", "Trying to parse xcconfig file \(url.absoluteString)")
		sourceURL = url
		
		var isDir = ObjCBool(false)
		if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
			if failIfFileDoesNotExist {
				throw XcodeProjKitError(message: "Cannot find xcconfig file at URL \(url.absoluteString)")
			} else {
				lines = []
				return
			}
		}
		if isDir.boolValue {
			/* We do not fail if the xcconfig file is a directory! This is the
			 * observed behaviour in Xcode. It simply gives a warning. */
			NSLog("%@", "Warning: Tried to import directory \(url.path) in an xcconfig file.")
			lines = []
			return
		}
		
		let fileContents = try String(contentsOf: url)
		
		var error: Error?
		var result = [Line]()
		fileContents.enumerateLines{ lineStr, stop in
			do {
				let line = try Line(lineString: lineStr, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters, allowSpacesAfterSharp: allowSpacesAfterSharp)
				result.append(line)
				
			} catch let e as Line.LineParsingError {
				stop = true
				switch e {
					case .unknownDirective(let directive):          error = XcodeProjKitError(message: "Unknown directive “\(directive)” in xcconfig file \(url.path).")
					case .gotSpaceAfterSharpInDirective:            error = XcodeProjKitError(message: "Got a space after # (directive start) in xcconfig file \(url.path).")
					case .expectedDoubleQuoteAfterIncludeDirective: error = XcodeProjKitError(message: "Expected a double-quote after include directive in xcconfig file \(url.path).")
					case .cannotParseIncludePath:                   error = XcodeProjKitError(message: "Cannot parse include directive path in xcconfig file \(url.path).")
					case .unexpectedCharAfterInclude:               error = XcodeProjKitError(message: "Unexpected characters after include directive in xcconfig file \(url.path).")
					case .invalidFirstCharInVar:                    error = XcodeProjKitError(message: "Invalid first char for a variable in xcconfig \(url.path).")
					case .unexpectedCharAfterVarName:               error = XcodeProjKitError(message: "Unexpected character after variable name in xcconfig \(url.path).")
				}
			} catch let e {
				stop = true
				error = e
			}
		}
		if let e = error {throw e}
		
		lines = result
	}
	
	public func urlFor(importPath path: String) throws -> URL {
		var path = path
		
		/* If path starts with <DEVELOPER_DIR>, the include is relative to the
		 * developer dir, says https://pewpewthespells.com/blog/xcconfig_guide.html
		 * (I have tested, it is true).
		 * From my testing, the replacement is done only if the token is the
		 * prefix of the path, and I did not find any other variable that can be
		 * used (tried SRCROOT).
		 *
		 * Something that’s hard to test and I didn’t is: Is the placeholder
		 * replaced if the path starts with “<DEVELOPER_DIR>” or with
		 * “<DEVELOPER_DIR>/”?
		 * We assume the former (I did a test which seems to show the placeholder
		 * is replaced when being on its own, but I cannot guarantee that’s true
		 * though). */
		if path.starts(with: "<DEVELOPER_DIR>") {
			let developerDir = try BuildSettings.getDeveloperDir()
//			let a = "/<DEVELOPER_DIR>/<DEVELOPER_DIR>"
//			print(a.replacingOccurrences(of: "<DEVELOPER_DIR>", with: developerDir, options: .anchored))
			/* Tested (commented code above): The line below does indeed replace
			 * the string only if it is the prefix of the var. */
			path = path.replacingOccurrences(of: "<DEVELOPER_DIR>", with: developerDir, options: .anchored)
		}
		
		return URL(fileURLWithPath: path, isDirectory: false, relativeTo: sourceURL)
	}
	
}

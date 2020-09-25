import Foundation



public struct XCConfig {
	
	public enum Line {
		
		public enum LineParsingError : Error {
			
			case unknownDirective(String)
			case gotSpaceAfterSharpInDirective
			case noSpaceAfterIncludeDirective
			case expectedDoubleQuoteAfterIncludeDirective
			case unterminatedIncludeFileName
			case unexpectedCharAfterInclude
			
			case invalidFirstCharInVar(Character)
			case unexpectedCharAfterVarName
			
		}
		
		case void(String)
		case include(path: String, isOptional: Bool, prefix: String, postSharp: String, postDirective: String, suffix: String)
		case value(key: BuildSettingKey, value: String, prefix: String, equalSign: String, suffix: String)
		
		init(lineString line: String, allowCommaSeparatorForParameters: Bool = false, allowSpacesAfterSharp: Bool = false, allowNoSpacesAfterInclude: Bool = false) throws {
			let lineContent, linePrefix, lineSuffix: String
			do {
				let components = line.components(separatedBy: "//")
				var lineContentBuilding = components.first!
				
				let lineCommentComponents = components[components.index(after: components.startIndex)..<components.endIndex]
				let lineComment: String
				if !lineCommentComponents.isEmpty {lineComment = "//" + lineCommentComponents.joined(separator: "//")}
				else                              {lineComment = ""}
				
				linePrefix = lineContentBuilding.removePrefix(from: Line.xcconfigWhitespace)
				let preCommentLineSuffix = lineContentBuilding.removeSuffix(from: Line.xcconfigWhitespace)
				
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
				let postSharp = scanner.scanCharacters(from: Line.xcconfigWhitespace) ?? ""
				/* It seems the xcconfig parser is not the same when compiling and
				 * in Xcode build settings UI.
				 * In the UI, the spaces after the sharp seem to break the xcconfig
				 * file fully; in code, the directive seems to work ok w/ spaces! */
				guard postSharp.isEmpty || allowSpacesAfterSharp else {throw LineParsingError.gotSpaceAfterSharpInDirective}
				
				let directive = scanner.scanUpToCharacters(from: Line.xcconfigWhitespace.union(CharacterSet(charactersIn: "?"))) ?? ""
				let isOptional = (scanner.scanString("?") != nil)
				let postDirective = scanner.scanCharacters(from: Line.xcconfigWhitespace) ?? ""
				switch directive {
					case "include":
						/* An empty post directive only works in the GUI of Xcode, not
						 * when building (Xcode 12.0.1 (12A7300)). */
						guard allowNoSpacesAfterInclude || !postDirective.isEmpty else {
							throw LineParsingError.noSpaceAfterIncludeDirective
						}
						guard scanner.scanString("\"") != nil else {
							throw LineParsingError.expectedDoubleQuoteAfterIncludeDirective
						}
						/* An empty path is valid… */
						let path = scanner.scanUpToString("\"") ?? ""
						guard scanner.scanString("\"") != nil else {
							throw LineParsingError.unterminatedIncludeFileName
						}
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
					guard let scalar = firstChar.unicodeScalars.first, firstChar.unicodeScalars.count == 1, BuildSettingKey.charactersValidForFirstVariableCharacter.contains(scalar) else {
						throw LineParsingError.invalidFirstCharInVar(firstChar)
					}
					let restOfVariableName = scanner.scanCharacters(from: BuildSettingKey.charactersValidInVariableName) ?? ""
					variableName = String(firstChar) + restOfVariableName
				}
				
				let parameters = BuildSettingKey.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
				
				let beforeEqualSign = scanner.scanCharacters(from: Line.xcconfigWhitespace) ?? ""
				guard scanner.scanString("=") != nil else {
					throw LineParsingError.unexpectedCharAfterVarName
				}
				
				let value: String
				let afterEqualSign, postVarSuffix: String
				do {
					var valueBuilding = scanner.scanUpToCharacters(from: CharacterSet()) ?? "" /* Scan to the end of string. */
					
					/* Find and trim the value prefix (whitespaces) */
					afterEqualSign = valueBuilding.removePrefix(from: Line.xcconfigWhitespace)
					
					/* Find and trim the value suffix (whitespaces + ";") */
					if valueBuilding.last == ";" {
						valueBuilding = String(valueBuilding[valueBuilding.startIndex..<valueBuilding.index(before: valueBuilding.endIndex)])
						postVarSuffix = valueBuilding.removeSuffix(from: Line.xcconfigWhitespace) + ";"
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
		
		var isValid: Bool {
			switch self {
				case .void(let str):
					let strTrimmed = str.trimmingCharacters(in: Line.xcconfigWhitespace)
					return strTrimmed.isEmpty || strTrimmed.hasPrefix("//")
					
				case .include(path: let path, isOptional: _, prefix: let prefix, postSharp: let postSharp, postDirective: let postDirective, suffix: let suffix):
					let suffixTrimmed = suffix.trimmingCharacters(in: Line.xcconfigWhitespace)
					let suffixOK = suffixTrimmed.isEmpty || suffixTrimmed.hasPrefix("//")
					let pathOK = (path.rangeOfCharacter(from: CharacterSet(charactersIn: "\n\""), options: .literal) == nil)
					let whitesOK = [prefix, postSharp, postDirective].first(where: { $0.rangeOfCharacter(from: Line.xcconfigWhitespace.inverted, options: .literal) != nil }) == nil
					/* An empty post directive only works in the GUI of Xcode, not
					 * when building (Xcode 12.0.1 (12A7300)). */
					let postDirectiveNotEmpty = !postDirective.isEmpty
					return whitesOK && pathOK && suffixOK && postDirectiveNotEmpty
					
				case .value(key: let key, value: let value, prefix: let prefix, equalSign: let equalSign, suffix: let suffix):
					let suffixTrimmed = suffix.trimmingCharacters(in: Line.xcconfigWhitespace)
					let prefixOK = prefix.rangeOfCharacter(from: Line.xcconfigWhitespace.inverted, options: .literal) == nil
					let suffixOK = suffixTrimmed.isEmpty || suffixTrimmed.hasPrefix("//")
					let keyOK = key.isValid(allowGarbage: true) /* We allow garbage because the garbage is correctly parsed and restituted */
					let valueOK = (value.range(of: "\n") == nil)
					let equalSignOK = (
						equalSign.rangeOfCharacter(from: Line.xcconfigWhitespace.union(CharacterSet(charactersIn: "=")).inverted, options: .literal) == nil &&
						equalSign.filter{ $0 == "=" }.count == 1
					)
					return prefixOK && suffixOK && keyOK && valueOK && equalSignOK
			}
		}
		
		func lineString() throws -> String {
			guard isValid else {
				throw XcodeProjKitError(message: "Trying to get line string representation of invalid line \(self)")
			}
			
			switch self {
				case .void(let str):
					return str
					
				case .include(path: let path, isOptional: let optional, prefix: let prefix, postSharp: let postSharp, postDirective: let postDirective, suffix: let suffix):
					return prefix + "#" + postSharp + "include" + (optional ? "?" : "") + postDirective + "\"" + path + "\"" + suffix
					
				case .value(key: let key, value: let value, prefix: let prefix, equalSign: let equalSign, suffix: let suffix):
					return prefix + key.serialized + equalSign + value + suffix
			}
		}
		
		/* We specifically want space and tabs; other unicode whitespaces are not
		 * valid for our use case. */
		static let xcconfigWhitespace = CharacterSet(charactersIn: " \t")
		
	}
	
	public struct LineID : Hashable, Comparable {
		
		public var lineNumber: Int
		public var precedence: Int = 0
		
		public static func < (lhs: XCConfig.LineID, rhs: XCConfig.LineID) -> Bool {
			if lhs.lineNumber < rhs.lineNumber {return true}
			if lhs.lineNumber > rhs.lineNumber {return false}
			return lhs.precedence < rhs.precedence
		}
		
	}
	
	public var sourceURL: URL
	public var lines: [LineID: Line]
	
	public var sortedLines: [(LineID, Line)] {
		return lines.sorted{ $0.key < $1.key }
	}
	
	public init(url: URL, failIfFileDoesNotExist: Bool = true, allowCommaSeparatorForParameters: Bool = false, allowSpacesAfterSharp: Bool = false, allowNoSpacesAfterInclude: Bool = false) throws {
//		NSLog("%@", "Trying to parse xcconfig file \(url.absoluteString)")
		sourceURL = url
		
		var isDir = ObjCBool(false)
		if !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
			if failIfFileDoesNotExist {
				throw XcodeProjKitError(message: "Cannot find xcconfig file at URL \(url.absoluteString)")
			} else {
				lines = [:]
				return
			}
		}
		if isDir.boolValue {
			/* We do not fail if the xcconfig file is a directory! This is the
			 * observed behaviour in Xcode. It simply gives a warning. */
			NSLog("%@", "Warning: Tried to import directory \(url.path) in an xcconfig file.")
			lines = [:]
			return
		}
		
		let fileContents = try String(contentsOf: url)
		
		var lineN = 0
		var error: Error?
		var result = [LineID: Line]()
		fileContents.enumerateLines{ lineStr, stop in
			do {
				let line = try Line(lineString: lineStr, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters, allowSpacesAfterSharp: allowSpacesAfterSharp, allowNoSpacesAfterInclude: allowNoSpacesAfterInclude)
				result[LineID(lineNumber: lineN)] = line
				lineN += 1
				
			} catch let e as Line.LineParsingError {
				stop = true
				switch e {
					case .unknownDirective(let directive):          error = XcodeProjKitError(message: "Unknown directive “\(directive)” in xcconfig file \(url.path).")
					case .gotSpaceAfterSharpInDirective:            error = XcodeProjKitError(message: "Got a space after # (directive start) in xcconfig file \(url.path).")
					case .noSpaceAfterIncludeDirective:             error = XcodeProjKitError(message: "No a space after #include in xcconfig file \(url.path). (This worked fine in previous versious versions of Xcode, but does not work anymore.)")
					case .expectedDoubleQuoteAfterIncludeDirective: error = XcodeProjKitError(message: "Expected a double-quote after include directive in xcconfig file \(url.path).")
					case .unterminatedIncludeFileName:              error = XcodeProjKitError(message: "Unterminated include file name in xcconfig file \(url.path).")
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


public typealias XCConfigRef = Ref<XCConfig>

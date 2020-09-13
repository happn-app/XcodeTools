import Foundation



/**
Represents a “level” of build settings.

This can either be an xcconfig file, or the project settings, or the settings of
a target.*/
public struct BuildSettings {
	
	/* Let’s get the developer dir! Our algo will be:
	 *    - If DEVELOPER_DIR env var is defined, use that;
	 *    - Otherwise try and get the path w/ xcode-select. */
	public static func getDeveloperDir() throws -> String {
		if let p = getenv("DEVELOPER_DIR") {
			return String(cString: p)
		}
		
		let p = Process()
		/* If the executable does not exist, the app crashes w/ an unhandled
		 * exception. We assume /usr/bin/env will always exist. */
		p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		p.arguments = ["/usr/bin/xcode-select", "-p"]
		
		p.standardInput = nil
		p.standardError = nil
		
		let pipe = Pipe()
		p.standardOutput = pipe
		
		p.launch()
		p.waitUntilExit()
		
		if #available(OSX 10.15.4, *) {
			guard let output = try pipe.fileHandleForReading.readToEnd().flatMap({ String(data: $0, encoding: .utf8) }), !output.isEmpty else {
				throw HagvtoolError(message: "Cannot get DEVELOPER_DIR")
			}
			return output.trimmingCharacters(in: .whitespacesAndNewlines)
		} else {
			throw HagvtoolError(message: "Cannot get DEVELOPER_DIR (because this program was not compiled on macOS 10.15.4)")
		}
	}
	
	public static func standardDefaultSettings(xcodprojURL: URL) -> BuildSettings {
		let projectDirPath = xcodprojURL.deletingLastPathComponent().path
		return BuildSettings(rawBuildSettings: [
			/* https://stackoverflow.com/a/43751741 */
			"PROJECT_DIR": projectDirPath,
			"PROJECT_FILE_PATH": xcodprojURL.path,
			"PROJECT_NAME": xcodprojURL.deletingPathExtension().lastPathComponent,
			"SRCROOT": projectDirPath,
			"SOURCE_ROOT": projectDirPath /* Unofficial alias of SRCROOT */
		])
	}
	
	public var settings: [BuildSetting]
	
	public init() {
		settings = []
	}
	
	public init(rawBuildSettings: [String: Any], allowCommaSeparatorForParameters: Bool = false) {
		settings = rawBuildSettings.map{ BuildSetting(laxSerializedKey: $0.key, value: $0.value, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters) }
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
		
		var error: Error?
		var result = [BuildSetting]()
		fileContents.enumerateLines{ line, stop in
			do {
				let line = line.components(separatedBy: "//").first!.trimmingCharacters(in: xcconfigWhitespace)
				guard !line.isEmpty else {return}
				
				let scanner = Scanner(forParsing: line)
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
							guard var filename = scanner.scanUpToString("\"") else {
								throw HagvtoolError(message: "Cannot parse include directive filename in xcconfig file \(url).")
							}
							_ = scanner.scanString("\"")
							guard scanner.isAtEnd else {
								throw HagvtoolError(message: "Unexpected characters after include directive in xcconfig file \(url).")
							}
							
							/* If filename starts with <DEVELOPER_DIR>, the include is
							 * relative to the developer dir, says https://pewpewthespells.com/blog/xcconfig_guide.html
							 * (I have tested, it is true).
							 * From my testing, the replacement is done only if the
							 * token is the prefix of the path, and I did not find any
							 * other variable that can be used (tried SRCROOT).
							 *
							 * Something that’s hard to test and I didn’t is: Is the
							 * placeholder replaced if the path starts w/
							 * “<DEVELOPER_DIR>” or w/ “<DEVELOPER_DIR>/”?
							 * We assume the former (I did a test which seems to show
							 * the placeholder is replaced when being on its own, but
							 * I cannot guarantee that’s true though). */
							if filename.starts(with: "<DEVELOPER_DIR>") {
								let developerDir = try BuildSettings.getDeveloperDir()
//								let a = "/<DEVELOPER_DIR>/<DEVELOPER_DIR>"
//								print(a.replacingOccurrences(of: "<DEVELOPER_DIR>", with: developerDir, options: .anchored))
								/* Tested (commented code above): The line below does
								 * indeed replace the string only if it is the prefix of
								 * the var. */
								filename = filename.replacingOccurrences(of: "<DEVELOPER_DIR>", with: developerDir, options: .anchored)
							}
							
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
						guard let scalar = firstChar.unicodeScalars.first, firstChar.unicodeScalars.count == 1, BuildSettings.charactersValidForFirstVariableCharacter.contains(scalar) else {
							throw HagvtoolError(message: "Invalid first char for a variable in xcconfig \(url.absoluteString).")
						}
						let restOfVariableName = scanner.scanCharacters(from: BuildSettings.charactersValidInVariableName) ?? ""
						variableName = String(firstChar) + restOfVariableName
					}
					
					let parameters = BuildSettingKey.parseSettingParams(scanner: scanner, allowCommaSeparator: allowCommaSeparatorForParameters)
					
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
					
					result.append(BuildSetting(key: BuildSettingKey(key: variableName, parameters: parameters), value: value))
				}
			} catch let e {
				stop = true
				error = e
			}
		}
		if let e = error {throw e}
		
		settings = result
	}
	
	static let charactersValidForFirstVariableCharacter = CharacterSet(charactersIn: "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	static let charactersValidInVariableName = charactersValidForFirstVariableCharacter.union(CharacterSet(charactersIn: "0123456789"))
	
}

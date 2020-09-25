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
				throw XcodeProjKitError(message: "Cannot get DEVELOPER_DIR")
			}
			return output.trimmingCharacters(in: .whitespacesAndNewlines)
		} else {
			throw XcodeProjKitError(message: "Cannot get DEVELOPER_DIR (because this program was not compiled on macOS 10.15.4)")
		}
	}
	
	public static func standardDefaultSettings(xcodprojURL: URL) -> BuildSettings {
		let projectDirPath = xcodprojURL.deletingLastPathComponent().path
		return BuildSettings(rawBuildSettings: [
			"HOME": FileManager.default.homeDirectoryForCurrentUser.path,
			
			/* https://stackoverflow.com/a/43751741 */
			"PROJECT_DIR": projectDirPath,
			"PROJECT_FILE_PATH": xcodprojURL.path,
			"PROJECT_NAME": xcodprojURL.deletingPathExtension().lastPathComponent,
			"SRCROOT": projectDirPath,
			"SOURCE_ROOT": projectDirPath /* Unofficial alias of SRCROOT */
		])
	}
	
	public var settings: [BuildSettingRef]
	
	public init() {
		settings = []
	}
	
	public init(rawBuildSettings: [String: Any], location: BuildSetting.Location = .none, allowCommaSeparatorForParameters: Bool = false) {
		settings = rawBuildSettings.map{ BuildSettingRef(BuildSetting(laxSerializedKey: $0.key, value: $0.value, location: location, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters)) }
	}
	
	public init(xcconfigURL url: URL, failIfFileDoesNotExist: Bool = true, allowCommaSeparatorForParameters: Bool = false, allowSpacesAfterSharp: Bool = false, allowNoSpacesAfterInclude: Bool = false) throws {
		try self.init(xcconfigURL: url, failIfFileDoesNotExist: failIfFileDoesNotExist, seenFiles: [], allowCommaSeparatorForParameters: allowCommaSeparatorForParameters, allowSpacesAfterSharp: allowSpacesAfterSharp, allowNoSpacesAfterInclude: allowNoSpacesAfterInclude)
	}
	
	private init(xcconfigURL url: URL, failIfFileDoesNotExist: Bool, seenFiles: Set<URL>, allowCommaSeparatorForParameters: Bool, allowSpacesAfterSharp: Bool, allowNoSpacesAfterInclude: Bool) throws {
		let xcconfig = try XCConfig(url: url, failIfFileDoesNotExist: failIfFileDoesNotExist, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters, allowSpacesAfterSharp: allowSpacesAfterSharp, allowNoSpacesAfterInclude: allowNoSpacesAfterInclude)
		let seenFiles = seenFiles.union([url.absoluteURL])
		let xcconfigRef = XCConfigRef(xcconfig)
		
		settings = try xcconfig.sortedLines.flatMap{ lineAndID -> [BuildSettingRef] in
			let (lineID, line) = lineAndID
			switch line {
				case .void:
					return []
					
				case .include(path: let path, isOptional: let isOptional, prefix: _, postSharp: _, postDirective: _, suffix: _):
					guard !path.isEmpty else {
						/* An empty path is ignored by Xcode with a warning AFAICT
						 * (Xcode 12.0.1 (12A7300)) */
						NSLog("%@", "Warning: Trying to import empty file path from \(url.path).")
						return []
					}
					
					let urlToImport = try xcconfig.urlFor(importPath: path)
					if !seenFiles.contains(urlToImport.absoluteURL) {
						let importedConfig = try BuildSettings(xcconfigURL: urlToImport, failIfFileDoesNotExist: !isOptional, seenFiles: seenFiles, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters, allowSpacesAfterSharp: allowSpacesAfterSharp, allowNoSpacesAfterInclude: allowNoSpacesAfterInclude)
						return importedConfig.settings
					} else {
						NSLog("%@", "Warning: Skipping include of \(urlToImport.absoluteString) to avoid cycling dependency from \(url.path).")
						return []
					}
					
				case .value(key: let key, value: let value, prefix: _, equalSign: _, suffix: _):
					return [BuildSettingRef(BuildSetting(key: key, value: value, location: .xcconfigFile(xcconfigRef, lineID: lineID)))]
			}
		}
	}
	
}


public typealias BuildSettingsRef = Ref<BuildSettings>

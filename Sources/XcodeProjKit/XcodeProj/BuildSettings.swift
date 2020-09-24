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
	
	public var settings: [BuildSetting]
	
	public init() {
		settings = []
	}
	
	public init(rawBuildSettings: [String: Any], allowCommaSeparatorForParameters: Bool = false) {
		settings = rawBuildSettings.map{ BuildSetting(laxSerializedKey: $0.key, value: $0.value, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters) }
	}
	
	public init(xcconfigURL url: URL, failIfFileDoesNotExist: Bool = true, allowCommaSeparatorForParameters: Bool = false) throws {
		throw XcodeProjKitError(message: "TODO")
	}
	
	static let charactersValidForFirstVariableCharacter = CharacterSet(charactersIn: "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	static let charactersValidInVariableName = charactersValidForFirstVariableCharacter.union(CharacterSet(charactersIn: "0123456789"))
	
}

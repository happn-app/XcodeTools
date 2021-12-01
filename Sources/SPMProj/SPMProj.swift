import Foundation



public struct SPMProj {
	
	public let rootURL: URL
	public let projectManifestURL: URL
	
	public init(path: String? = nil) throws {
		self.rootURL = URL(fileURLWithPath: path ?? ".")
		self.projectManifestURL = rootURL.appendingPathComponent("Package.swift")
		
		/* For now we only validate the existence of the Package.swift file; later we’ll try and parse it. */
		var isDir = ObjCBool(false)
		guard FileManager.default.fileExists(atPath: projectManifestURL.path, isDirectory: &isDir), !isDir.boolValue else {
			throw Err.invalidProjectPath(rootURL)
		}
	}
	
}

import Foundation



struct VersionInfo_Plist {
	
	static let path = "VersionInfo.plist"
	static var fileContent: Data {return Data(base64Encoded: fileContentBase64)!}
	
	static func write(in modelDirectoryURL: URL) throws {
		try fileContent.write(to: modelDirectoryURL.appendingPathComponent(path), options: .withoutOverwriting)
	}
	
	private init() {}
	
	private static let fileContentBase64 = (
		"YnBsaXN0MDDRAQJfECJOU01hbmFnZWRPYmplY3RNb2RlbF9WZXJzaW9uSGFzaGVz0QMEXx" +
		"APaGFwcFNpZ2h0IE1vZGVs0gUGBwhVRXZlbnRYVXNlckluZm9PECDLyg4DIVSzI9m3f8Pz" +
		"uyVRFk0gn113L41ssggCghYDmU8QIMuB87JCiZPJLtaR10BP27NUvzvPe7GjcRGBviw5ML" +
		"xYCAswM0VKUFl8AAAAAAAAAQEAAAAAAAAACQAAAAAAAAAAAAAAAAAAAJ8="
	)
	
}

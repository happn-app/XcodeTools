import Foundation



public struct PbxProj {
	
	public let rawDecoded: [String: Any]
	
	/** Should always be 1 (only version supported). */
	public let archiveVersion: String
	
	/**
	Usually 52 or 53 (starting w/ Xcode 11.4). We support these two versions
	only. */
	public let objectVersion: String
	
	/** The ID of the root object. */
	public let rootObjectID: String
	
	/**
	All the objects in the project, keyed by their IDs. */
	public let rawObjects: [String: [String: Any]]
	
	public let rootObject: PbxProject
	
	public init(url: URL) throws {
		let data = try Data(contentsOf: url)
		
		//var format = PropertyListSerialization.PropertyListFormat.xml
		guard let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil/*&format*/) as? [String: Any] else {
			throw HagvtoolError(message: "Got unexpected type for decoded pbxproj plist (not [String: Any]) in pbxproj.")
		}
		/* Now, "format" is (should be) PropertyListSerialization.PropertyListFormat.openStep */
		
		rawDecoded = decoded
		
		guard let av = rawDecoded["archiveVersion"] as? String, av == "1" else {
			throw HagvtoolError(message: "Got unexpected type or value for the “archiveVersion” property in pbxproj.")
		}
		archiveVersion = av
		
		guard let ov = rawDecoded["objectVersion"] as? String, (ov == "52" || ov == "53") else {
			throw HagvtoolError(message: "Got unexpected type or value for the “objectVersion” property in pbxproj.")
		}
		objectVersion = ov
		
		guard let classes = rawDecoded["classes"] as? [String: Any], classes.isEmpty else {
			throw HagvtoolError(message: "The “classes” property is not empty or not an array in pbxproj; bailing out because we don’t know what this means.")
		}
		
		guard let r = rawDecoded["rootObject"] as? String else {
			throw HagvtoolError(message: "Got unexpected type for the “rootObject” property in pbxproj.")
		}
		rootObjectID = r
		
		guard let o = rawDecoded["objects"] as? [String: [String: Any]] else {
			throw HagvtoolError(message: "Got unexpected type for the “objects” property in pbxproj.")
		}
		rawObjects = o
		
		guard rawDecoded.count == 5 else {
			throw HagvtoolError(message: "Got unexpected properties in pbxproj.")
		}
		
		rootObject = try PbxProject(rawObjects: rawObjects, id: rootObjectID)
	}
	
}

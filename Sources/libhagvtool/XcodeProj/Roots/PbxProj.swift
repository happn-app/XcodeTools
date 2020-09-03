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
	
	public let rootObject: PBXProject
	
	public init(url: URL) throws {
		let data = try Data(contentsOf: url)
		
		//var format = PropertyListSerialization.PropertyListFormat.xml
		guard let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil/*&format*/) as? [String: Any] else {
			throw HagvtoolError(message: "Got unexpected type for decoded pbxproj plist (not [String: Any]) in pbxproj.")
		}
		/* Now, "format" is (should be) PropertyListSerialization.PropertyListFormat.openStep */
		
		rawDecoded = decoded
		
		archiveVersion = try rawDecoded.get("archiveVersion")
		guard archiveVersion == "1" else {
			throw HagvtoolError(message: "Got unexpected value for the “archiveVersion” property in pbxproj.")
		}
		
		let ov: String = try rawDecoded.get("objectVersion")
		guard ov == "52" || ov == "53" else {
			throw HagvtoolError(message: "Got unexpected value for the “objectVersion” property in pbxproj.")
		}
		objectVersion = ov
		
		let classes: [String: Any] = try rawDecoded.get("classes")
		guard classes.isEmpty else {
			throw HagvtoolError(message: "The “classes” property is not empty in pbxproj; bailing out because we don’t know what this means.")
		}
		
		rootObjectID = try rawDecoded.get("rootObject")
		rawObjects = try rawDecoded.get("objects")
		
		guard rawDecoded.count == 5 else {
			throw HagvtoolError(message: "Got unexpected properties in pbxproj.")
		}
		
		let factory = PBXObjectFactory(objectNames: pbxObjectClasses, targetNames: pbxTargetClasses)
		rootObject = try PBXProject(rawObjects: rawObjects, id: rootObjectID, factory: factory)
	}
	
}

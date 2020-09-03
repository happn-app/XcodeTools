import Foundation



public struct PBXProject : PBXObject {
	
	public static var isa = "PBXProject"
	
	public let rawObject: [String: Any]
	
	/** We do not use this but maybe we should… */
	public let compatibilityVersion: String
	
	public let projectRoot: String
	public let projectDirPath: String
	
	public let buildConfigurationList: XCConfigurationList
	public let targets: [PBXTarget]
	
	/* Note: There are other known properties in this object, but we do not use
	 * them, so we do not mention them. */
	
	public init(rawObjects: [String: [String: Any]], id: String, factory: PBXObjectFactory) throws {
		guard let o = rawObjects[id], o["isa"] as? String == Self.isa else {
			throw HagvtoolError(message: "Cannot find object with id \(id) to init a \(Self.isa)")
		}
		rawObject = o
		
		compatibilityVersion = try rawObject.get("compatibilityVersion")
		
		projectRoot = try rawObject.get("projectRoot")
		projectDirPath = try rawObject.get("projectDirPath")
		guard projectRoot == "", projectDirPath == "" else {
			throw HagvtoolError(message: "Don’t know how to handle non-empty projectRoot or projectDirPath.")
		}
		
		let targetIDs: [String] = try rawObject.get("targets")
		targets = try targetIDs.map{ try factory.instantiateTarget(rawObjects: rawObjects, id: $0) }
		
		let buildConfigurationListID: String = try rawObject.get("buildConfigurationList")
		buildConfigurationList = try XCConfigurationList(rawObjects: rawObjects, id: buildConfigurationListID, factory: factory)
	}
	
}

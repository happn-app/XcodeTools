import Foundation



public struct PbxProject {
	
	public static var isa = "PBXProject"
	
	public let rawObject: [String: Any]
	
	/** We do not use this but maybe we should… */
	public let compatibilityVersion: String
	
	public let targets: [PbxNativeTarget]
	
	/* Note: There are other known properties in this object, but we do not use
	 * them, so we do not mention them. */
	
	public init(rawObjects: [String: [String: Any]], id: String) throws {
		guard let o = rawObjects[id], o["isa"] as? String == Self.isa else {
			throw HagvtoolError(message: "Cannot find object with id \(id) to init a \(Self.isa)")
		}
		rawObject = o
		
		guard let cv = rawObject["compatibilityVersion"] as? String else {
			throw HagvtoolError(message: "Got unexpected type for compatibilityVersion in a PBXProject.")
		}
		compatibilityVersion = cv
		
		guard let targetIDs = rawObject["targets"] as? [String] else {
			throw HagvtoolError(message: "Did not get a targets String array in a PBXProject object.")
		}
		targets = try targetIDs.map{ try PbxNativeTarget(rawObjects: rawObjects, id: $0) }
	}
	
}

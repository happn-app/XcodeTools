import Foundation



public struct XCConfigurationList : PBXObject {
	
	public static var isa = "XCConfigurationList"
	
	public let rawObject: [String: Any]
	
	/* Note: There are other known properties in this object, but we do not use
	 * them, so we do not mention them. */
	
	public init(rawObjects: [String: [String: Any]], id: String, factory: PBXObjectFactory) throws {
		guard let o = rawObjects[id], o["isa"] as? String == Self.isa else {
			throw HagvtoolError(message: "Cannot find object with id \(id) to init a \(Self.isa)")
		}
		rawObject = o
	}
	
}

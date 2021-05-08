import Foundation



public struct StreamedEvent : _Object {
	
	static let type = ObjectType(name: "StreamedEvent")
	
	public var name: String
//	public var structuredPayload: AnyObject
	
	init(dictionary: [String: Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard dictionary.count == 3 else {
			throw NSError()
		}
		guard let nameJson = dictionary["name"] as? [String: Any?] else {
			throw NSError()
		}
		self.name = try String(dictionary: nameJson)
	}
	
}

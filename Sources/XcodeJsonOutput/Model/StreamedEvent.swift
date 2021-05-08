import Foundation



public struct StreamedEvent : _Object {
	
	static let type = ObjectType(name: "StreamedEvent")
	
	public var name: String
//	public var structuredPayload: AnyObject
	
	init(dictionary: [String: Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard
			dictionary.count == 3,
			let nameDic = dictionary["name"] as? [String: Any?],
			let payloadDic = dictionary["structuredPayload"] as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.name = try String(dictionary: nameDic)
	}
	
}

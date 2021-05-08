import Foundation



public struct StreamedEvent : _Object {
	
	static let type = ObjectType(name: "StreamedEvent")
	
	public var name: String
	public var structuredPayload: AnyStreamedEventPayload
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let nameDic    = dictionary.removeValue(forKey: "name")              as? [String: Any?],
			let payloadDic = dictionary.removeValue(forKey: "structuredPayload") as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.name              = try .init(dictionary: nameDic)
		self.structuredPayload = try Parser.parsePayload(dictionary: payloadDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



public struct StreamedEvent : _Object {
	
	static let type = ObjectType(name: "StreamedEvent")
	
	public var name: String
	public var structuredPayload: AnyStreamedEventPayload
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.name              = try dictionary.getParsedAndRemove("name")
		self.structuredPayload = try Parser.parsePayload(dictionary: dictionary.getAndRemove("structuredPayload", notFoundError: Err.malformedObject, wrongTypeError: Err.malformedObject))
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

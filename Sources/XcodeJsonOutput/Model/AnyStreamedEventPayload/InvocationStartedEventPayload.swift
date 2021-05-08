import Foundation



struct InvocationStartedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "InvocationStartedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var metadata: ActionsInvocationMetadata
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let metadataDic = dictionary.removeValue(forKey: "metadata") as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.metadata = try .init(dictionary: metadataDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

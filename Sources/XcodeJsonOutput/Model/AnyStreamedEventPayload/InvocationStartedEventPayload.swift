import Foundation



struct InvocationStartedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "InvocationStartedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var metadata: ActionsInvocationMetadata
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.metadata = try dictionary.getParsedAndRemove("metadata")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

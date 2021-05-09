import Foundation



struct InvocationFinishedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "InvocationFinishedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var recordRef: Reference
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.recordRef = try dictionary.getParsedAndRemove("recordRef")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ActionStartedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "ActionStartedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var actionInfo: StreamedActionInfo
	var head: ActionRecordHead
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.actionInfo = try dictionary.getParsedAndRemove("actionInfo")
		self.head       = try dictionary.getParsedAndRemove("head")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

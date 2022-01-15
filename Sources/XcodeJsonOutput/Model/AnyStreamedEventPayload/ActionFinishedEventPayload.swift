import Foundation



struct ActionFinishedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "ActionFinishedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var actionInfo: StreamedActionInfo
	var tail: ActionRecordTail
	
	init(dictionary originalDictionary: [String : Any?], parentPropertyName: String?) throws {
		var dictionary = originalDictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary, parentPropertyName: parentPropertyName)
		
		self.actionInfo = try dictionary.getParsedAndRemove("actionInfo", originalDictionary)
		self.tail       = try dictionary.getParsedAndRemove("tail", originalDictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
#warning("TODO")
		return nil
	}
	
}

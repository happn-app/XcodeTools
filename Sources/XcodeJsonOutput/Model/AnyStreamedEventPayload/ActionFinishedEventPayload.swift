import Foundation



struct ActionFinishedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "ActionFinishedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var actionInfo: StreamedActionInfo
	var tail: ActionRecordTail
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.actionInfo = try dictionary.getParsedAndRemove("actionInfo")
		self.tail       = try dictionary.getParsedAndRemove("tail")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
		#warning("TODO")
		return nil
	}
	
}

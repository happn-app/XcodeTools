import Foundation



struct LogSectionAttachedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogSectionAttachedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var childSectionIndex: Int
	var parentSectionIndex: Int?
	var resultInfo: StreamedActionResultInfo
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.childSectionIndex  = try dictionary.getParsedAndRemove("childSectionIndex")
		self.parentSectionIndex = try dictionary.getParsedIfExistsAndRemove("parentSectionIndex")
		self.resultInfo         = try dictionary.getParsedAndRemove("resultInfo")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
		#warning("TODO")
		return nil
	}
	
}

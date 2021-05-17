import Foundation



struct LogSectionClosedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogSectionClosedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int
	var tail: AnyActivityLogSectionTail
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.resultInfo   = try dictionary.getParsedAndRemove("resultInfo")
		self.sectionIndex = try dictionary.getParsedAndRemove("sectionIndex")
		self.tail         = try Parser.parseActivityLogSectionTail(dictionary: dictionary.getAndRemove("tail", notFoundError: Err.malformedObject, wrongTypeError: Err.malformedObject))
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
		#warning("TODO")
		return nil
	}
	
}

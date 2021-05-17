import Foundation



struct LogTextAppendedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogTextAppendedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int
	var text: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.resultInfo   = try dictionary.getParsedAndRemove("resultInfo")
		self.sectionIndex = try dictionary.getParsedAndRemove("sectionIndex")
		self.text         = try dictionary.getParsedAndRemove("text")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	func humanReadableEvent(withColors: Bool) -> String? {
		#warning("TODO")
		return nil
	}
	
}

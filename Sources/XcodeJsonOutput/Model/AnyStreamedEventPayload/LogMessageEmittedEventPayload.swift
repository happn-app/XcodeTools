import Foundation



struct LogMessageEmittedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogMessageEmittedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var message: ActivityLogMessage
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.message      = try dictionary.getParsedAndRemove("message")
		self.resultInfo   = try dictionary.getParsedAndRemove("resultInfo")
		self.sectionIndex = try dictionary.getParsedAndRemove("sectionIndex")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

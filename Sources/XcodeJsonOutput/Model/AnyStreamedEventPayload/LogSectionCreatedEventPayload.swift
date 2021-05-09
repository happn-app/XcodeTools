import Foundation



struct LogSectionCreatedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogSectionCreatedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var head: AnyActivityLogSectionHead
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int

	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.head         = try Parser.parseActivityLogSectionHead(dictionary: dictionary.getAndRemove("head", notFoundError: Err.malformedObject, wrongTypeError: Err.malformedObject))
		self.resultInfo   = try dictionary.getParsedAndRemove("resultInfo")
		self.sectionIndex = try dictionary.getParsedAndRemove("sectionIndex")

		Self.logUnknownKeys(from: dictionary)
	}
	
}

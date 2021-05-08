import Foundation



struct LogMessageEmittedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogMessageEmittedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var message: ActivityLogMessage
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let messageDic      = dictionary.removeValue(forKey: "message")      as? [String: Any?],
			let resultInfoDic   = dictionary.removeValue(forKey: "resultInfo")   as? [String: Any?],
			let sectionIndexDic = dictionary.removeValue(forKey: "sectionIndex") as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.message      = try .init(dictionary: messageDic)
		self.resultInfo   = try .init(dictionary: resultInfoDic)
		self.sectionIndex = try .init(dictionary: sectionIndexDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

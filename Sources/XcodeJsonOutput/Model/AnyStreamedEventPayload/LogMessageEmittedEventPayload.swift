import Foundation



struct LogMessageEmittedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "LogMessageEmittedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var message: ActivityLogMessage
	var resultInfo: StreamedActionResultInfo
	var sectionIndex: Int
	
	init(dictionary: [String : Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard
			dictionary.count == 4,
			let messageDic      = dictionary["message"]      as? [String: Any?],
			let resultInfoDic   = dictionary["resultInfo"]   as? [String: Any?],
			let sectionIndexDic = dictionary["sectionIndex"] as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.message = try ActivityLogMessage(dictionary: messageDic)
		self.resultInfo = try StreamedActionResultInfo(dictionary: resultInfoDic)
		self.sectionIndex = try Int(dictionary: sectionIndexDic)
	}
	
}

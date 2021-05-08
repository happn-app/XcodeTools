import Foundation



struct ActionStartedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "ActionStartedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var actionInfo: StreamedActionInfo
	var head: ActionRecordHead
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let actionInfoDic = dictionary.removeValue(forKey: "actionInfo") as? [String: Any?],
			let headDic       = dictionary.removeValue(forKey: "head")       as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.actionInfo = try .init(dictionary: actionInfoDic)
		self.head       = try .init(dictionary: headDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ActionRecordHead : _Object {
	
	static var type: ObjectType = .init(name: "ActionRecordHead")
	
	var runDestination: ActionRunDestinationRecord
	var schemeCommandName: String
	var schemeTaskName: String
	var startedTime: Date
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let runDestinationDic    = dictionary.removeValue(forKey: "runDestination")    as? [String: Any?],
			let schemeCommandNameDic = dictionary.removeValue(forKey: "schemeCommandName") as? [String: Any?],
			let schemeTaskNameDic    = dictionary.removeValue(forKey: "schemeTaskName")    as? [String: Any?],
			let startedTimeDic       = dictionary.removeValue(forKey: "startedTime")       as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.runDestination    = try ActionRunDestinationRecord(dictionary: runDestinationDic)
		self.schemeCommandName = try String(dictionary: schemeCommandNameDic)
		self.schemeTaskName    = try String(dictionary: schemeTaskNameDic)
		self.startedTime       = try Date(dictionary: startedTimeDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

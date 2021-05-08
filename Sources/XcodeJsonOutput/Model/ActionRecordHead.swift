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
		
		self.runDestination    = try dictionary.getParsedAndRemove("runDestination")
		self.schemeCommandName = try dictionary.getParsedAndRemove("schemeCommandName")
		self.schemeTaskName    = try dictionary.getParsedAndRemove("schemeTaskName")
		self.startedTime       = try dictionary.getParsedAndRemove("startedTime")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ActionRecordTail : _Object {
	
	static var type: ObjectType = .init(name: "ActionRecordTail")
	
	var actionResult: ActionResult
	var buildResult: ActionResult
	var endedTime: Date
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.actionResult = try dictionary.getParsedAndRemove("actionResult")
		self.buildResult  = try dictionary.getParsedAndRemove("buildResult")
		self.endedTime    = try dictionary.getParsedAndRemove("endedTime")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

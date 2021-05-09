import Foundation



struct ActivityLogSectionTail : _AnyActivityLogSectionTail {
	
	static var type: ObjectType = .init(name: "ActivityLogSectionTail")
	
	var duration: Double
	var result: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.duration = try dictionary.getParsedAndRemove("duration")
		self.result   = try dictionary.getParsedAndRemove("result")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

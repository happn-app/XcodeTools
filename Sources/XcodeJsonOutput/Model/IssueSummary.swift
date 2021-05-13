import Foundation



struct IssueSummary : _Object {
	
	static var type: ObjectType = .init(name: "IssueSummary")
	
	var issueType: String
	var message: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.issueType = try dictionary.getParsedAndRemove("issueType")
		self.message   = try dictionary.getParsedAndRemove("message")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

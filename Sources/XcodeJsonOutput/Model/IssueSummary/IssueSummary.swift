import Foundation



struct IssueSummary : _AnyIssueSummary {
	
	static var type: ObjectType = .init(name: "IssueSummary")
	
	var issueType: String
	var message: String
	
	init(dictionary originalDictionary: [String : Any?], parentPropertyName: String?) throws {
		var dictionary = originalDictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary, parentPropertyName: parentPropertyName)
		
		self.issueType = try dictionary.getParsedAndRemove("issueType", originalDictionary)
		self.message   = try dictionary.getParsedAndRemove("message", originalDictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ResultIssueSummaries : _Object {
	
	static var type: ObjectType = .init(name: "ResultIssueSummaries")
	
	var errorSummaries: [IssueSummary]?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.errorSummaries = try dictionary.getParsedIfExistsAndRemove("errorSummaries")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

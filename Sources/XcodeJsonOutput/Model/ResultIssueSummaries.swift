import Foundation



struct ResultIssueSummaries : _Object {
	
	static var type: ObjectType = .init(name: "ResultIssueSummaries")
	
	var warningSummaries: [IssueSummary]
	var errorSummaries: [IssueSummary]
	var testFailureSummaries: [TestFailureIssueSummary]

	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.warningSummaries     = try dictionary.getParsedIfExistsAndRemove("warningSummaries")     ?? []
		self.errorSummaries       = try dictionary.getParsedIfExistsAndRemove("errorSummaries")       ?? []
		self.testFailureSummaries = try dictionary.getParsedIfExistsAndRemove("testFailureSummaries") ?? []
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct TestFailureIssueSummary : _AnyIssueSummary {
	
	static var type: ObjectType = .init(name: "TestFailureIssueSummary", supertype: .init(name: "IssueSummary"))
	
	var issueType: String
	var message: String
	
	var testCaseName: String
	var producingTarget: String
	var documentLocationInCreatingWorkspace: DocumentLocation
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.issueType = try dictionary.getParsedAndRemove("issueType")
		self.message   = try dictionary.getParsedAndRemove("message")
		
		self.testCaseName                        = try dictionary.getParsedAndRemove("testCaseName")
		self.producingTarget                     = try dictionary.getParsedAndRemove("producingTarget")
		self.documentLocationInCreatingWorkspace = try dictionary.getParsedAndRemove("documentLocationInCreatingWorkspace")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

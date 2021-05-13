import Foundation



struct IssueEmittedEventPayload : _AnyStreamedEventPayload {
	
	static var type: ObjectType = .init(name: "IssueEmittedEventPayload", supertype: .init(name: "AnyStreamedEventPayload"))
	
	var issue: IssueSummary
	var resultInfo: StreamedActionResultInfo
	var severity: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.issue      = try dictionary.getParsedAndRemove("issue")
		self.resultInfo = try dictionary.getParsedAndRemove("resultInfo")
		self.severity   = try dictionary.getParsedAndRemove("severity")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

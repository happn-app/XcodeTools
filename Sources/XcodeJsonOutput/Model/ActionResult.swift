import Foundation



struct ActionResult : _Object {
	
	static var type: ObjectType = .init(name: "ActionResult")
	
	var coverage: CodeCoverageInfo
	var issues: ResultIssueSummaries
	var metrics: ResultMetrics
	var resultName: String
	var status: String
	var testsRef: Reference?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.coverage   = try dictionary.getParsedAndRemove("coverage")
		self.issues     = try dictionary.getParsedAndRemove("issues")
		self.metrics    = try dictionary.getParsedAndRemove("metrics")
		self.resultName = try dictionary.getParsedAndRemove("resultName")
		self.status     = try dictionary.getParsedAndRemove("status")
		self.testsRef   = try dictionary.getParsedIfExistsAndRemove("testsRef")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

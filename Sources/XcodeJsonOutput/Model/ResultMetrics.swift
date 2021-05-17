import Foundation



struct ResultMetrics : _Object {
	
	static var type: ObjectType = .init(name: "ResultMetrics")
	
	var warningCount: Int
	var errorCount: Int
	
	var testsCount: Int
	var testsFailedCount: Int
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.warningCount = try dictionary.getParsedIfExistsAndRemove("warningCount") ?? 0
		self.errorCount   = try dictionary.getParsedIfExistsAndRemove("errorCount")   ?? 0
		
		self.testsCount       = try dictionary.getParsedIfExistsAndRemove("testsCount")       ?? 0
		self.testsFailedCount = try dictionary.getParsedIfExistsAndRemove("testsFailedCount") ?? 0
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

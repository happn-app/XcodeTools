import Foundation



struct ResultMetrics : _Object {
	
	static var type: ObjectType = .init(name: "ResultMetrics")
	
	var errorCount: Int?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.errorCount = try dictionary.getParsedIfExistsAndRemove("errorCount")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

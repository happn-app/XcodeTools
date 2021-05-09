import Foundation



struct ResultIssueSummaries : _Object {
	
	static var type: ObjectType = .init(name: "ResultIssueSummaries")
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

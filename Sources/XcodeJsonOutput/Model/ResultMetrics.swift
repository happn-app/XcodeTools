import Foundation



struct ResultMetrics : _Object {
	
	static var type: ObjectType = .init(name: "ResultMetrics")
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



extension Int : _Object {
	
	static let type = ObjectType(name: "Int")
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let valueStr = dictionary.removeValue(forKey: "_value") as? String,
			let value = Int(valueStr)
		else {
			throw Err.malformedObject
		}
		
		self = value
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}
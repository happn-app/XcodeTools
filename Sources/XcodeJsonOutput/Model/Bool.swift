import Foundation



extension Bool : _Object {
	
	static let type = ObjectType(name: "Bool")
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let valueStr = dictionary.removeValue(forKey: "_value") as? String,
			let value = Bool(valueStr)
		else {
			throw Err.malformedObject
		}
		
		self = value
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



extension Double : _Object {
	
	static let type = ObjectType(name: "Double")
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let valueStr = dictionary.removeValue(forKey: "_value") as? String,
			let value = Double(valueStr)
		else {
			throw Err.malformedObject
		}
		
		self = value
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

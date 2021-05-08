import Foundation



extension String : _Object {
	
	static let type = ObjectType(name: "String")
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let value = dictionary.removeValue(forKey: "_value") as? String
		else {
			throw Err.malformedObject
		}
		
		self = value
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

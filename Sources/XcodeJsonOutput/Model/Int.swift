import Foundation



extension Int : _Object {
	
	static let type = ObjectType(name: "Int")
	
	init(dictionary: [String: Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard
			dictionary.count == 2,
			let valueStr = dictionary["_value"] as? String,
			let value = Int(valueStr)
		else {
			throw Err.malformedObject
		}
		
		self = value
	}
	
}

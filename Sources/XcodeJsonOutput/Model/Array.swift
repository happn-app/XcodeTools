import Foundation



extension Array : Object where Element : Object {
}


extension Array : _Object where Element : _Object {

	static var type: ObjectType {ObjectType(name: "Array")}
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard let values = dictionary.removeValue(forKey: "_values") as? [[String: Any?]] else {
			throw Err.malformedObject
		}
		
		self = try values.map{ try Element.init(dictionary: $0) }
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

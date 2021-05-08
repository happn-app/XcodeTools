import Foundation



extension String : _Object {
	
	static let type = ObjectType(name: "String")
	
	init(dictionary: [String: Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard dictionary.count == 2 else {
			throw NSError()
		}
		guard let value = dictionary["_value"] as? String else {
			throw NSError()
		}
		self = value
	}
	
}

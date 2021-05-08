import Foundation



struct ActionPlatformRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionPlatformRecord")
	
	var identifier: String
	var userDescription: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.identifier      = try dictionary.getParsedAndRemove("identifier")
		self.userDescription = try dictionary.getParsedAndRemove("userDescription")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

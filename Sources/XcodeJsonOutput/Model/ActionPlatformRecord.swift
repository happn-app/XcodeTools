import Foundation



struct ActionPlatformRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionPlatformRecord")
	
	var identifier: String
	var userDescription: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let identifierDic      = dictionary.removeValue(forKey: "identifier")    as? [String: Any?],
			let userDescriptionDic = dictionary.removeValue(forKey: "userDescription") as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.identifier      = try String(dictionary: identifierDic)
		self.userDescription = try String(dictionary: userDescriptionDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ActionSDKRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionSDKRecord")
	
	var identifier: String
	var name: String
	var operatingSystemVersion: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let identifierDic             = dictionary.removeValue(forKey: "identifier")             as? [String: Any?],
			let nameDic                   = dictionary.removeValue(forKey: "name")                   as? [String: Any?],
			let operatingSystemVersionDic = dictionary.removeValue(forKey: "operatingSystemVersion") as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.identifier             = try .init(dictionary: identifierDic)
		self.name                   = try .init(dictionary: nameDic)
		self.operatingSystemVersion = try .init(dictionary: operatingSystemVersionDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



struct ActionSDKRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionSDKRecord")
	
	var identifier: String
	var name: String
	var operatingSystemVersion: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.identifier             = try dictionary.getParsedAndRemove("identifier")
		self.name                   = try dictionary.getParsedAndRemove("name")
		self.operatingSystemVersion = try dictionary.getParsedAndRemove("operatingSystemVersion")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

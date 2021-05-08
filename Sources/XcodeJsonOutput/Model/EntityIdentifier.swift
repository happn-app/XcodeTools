import Foundation



struct EntityIdentifier : _Object {
	
	static var type: ObjectType = .init(name: "EntityIdentifier")
	
	var containerName: String
	var entityName: String
	var entityType: String
	var sharedState: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.containerName = try dictionary.getParsedAndRemove("containerName")
		self.entityName    = try dictionary.getParsedAndRemove("entityName")
		self.entityType    = try dictionary.getParsedAndRemove("entityType")
		self.sharedState   = try dictionary.getParsedAndRemove("sharedState")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

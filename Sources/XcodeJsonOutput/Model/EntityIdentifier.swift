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
		
		guard
			let containerNameDic = dictionary.removeValue(forKey: "containerName") as? [String: Any?],
			let entityNameDic    = dictionary.removeValue(forKey: "entityName")    as? [String: Any?],
			let entityTypeDic    = dictionary.removeValue(forKey: "entityType")    as? [String: Any?],
			let sharedStateDic   = dictionary.removeValue(forKey: "sharedState")   as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.containerName = try .init(dictionary: containerNameDic)
		self.entityName    = try .init(dictionary: entityNameDic)
		self.entityType    = try .init(dictionary: entityTypeDic)
		self.sharedState   = try .init(dictionary: sharedStateDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

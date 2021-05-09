import Foundation



struct Reference : _Object {
	
	static var type: ObjectType = .init(name: "Reference")
	
	var id: String
	var targetType: TypeDefinition
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.id         = try dictionary.getParsedAndRemove("id")
		self.targetType = try dictionary.getParsedAndRemove("targetType")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

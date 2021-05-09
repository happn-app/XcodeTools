import Foundation



public struct TypeDefinition : _Object {
	
	static let type = ObjectType(name: "TypeDefinition")
	
	public var name: String
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.name = try dictionary.getParsedAndRemove("name")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



public struct TypeDefinition : _Object {
	
	static let type = ObjectType(name: "TypeDefinition")
	
	public var name: String
	
	init(dictionary originalDictionary: [String: Any?], parentPropertyName: String?) throws {
		var dictionary = originalDictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary, parentPropertyName: parentPropertyName)
		
		self.name = try dictionary.getParsedAndRemove("name", originalDictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

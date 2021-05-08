import Foundation



struct ActionsInvocationMetadata : _Object {
	
	static var type: ObjectType = .init(name: "ActionsInvocationMetadata")
	
	var creatingWorkspaceFilePath: String
	var schemeIdentifier: EntityIdentifier
	var uniqueIdentifier: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let creatingWorkspaceFilePathDic = dictionary.removeValue(forKey: "creatingWorkspaceFilePath") as? [String: Any?],
			let schemeIdentifierDic          = dictionary.removeValue(forKey: "schemeIdentifier")          as? [String: Any?],
			let uniqueIdentifierDic          = dictionary.removeValue(forKey: "uniqueIdentifier")          as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.creatingWorkspaceFilePath = try .init(dictionary: creatingWorkspaceFilePathDic)
		self.schemeIdentifier          = try .init(dictionary: schemeIdentifierDic)
		self.uniqueIdentifier          = try .init(dictionary: uniqueIdentifierDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

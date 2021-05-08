import Foundation



struct ActionsInvocationMetadata : _Object {
	
	static var type: ObjectType = .init(name: "ActionsInvocationMetadata")
	
	var creatingWorkspaceFilePath: String
	var schemeIdentifier: EntityIdentifier
	var uniqueIdentifier: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.creatingWorkspaceFilePath = try dictionary.getParsedAndRemove("creatingWorkspaceFilePath")
		self.schemeIdentifier          = try dictionary.getParsedAndRemove("schemeIdentifier")
		self.uniqueIdentifier          = try dictionary.getParsedAndRemove("uniqueIdentifier")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

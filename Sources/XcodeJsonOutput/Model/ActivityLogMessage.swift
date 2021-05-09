import Foundation



struct ActivityLogMessage : _Object {

	static var type: ObjectType = .init(name: "ActivityLogMessage")
	
	var title: String
	var shortTitle: String
	
	var type: String
	var category: String
	
	var location: DocumentLocation?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.title      = try dictionary.getParsedAndRemove("title")
		self.shortTitle = try dictionary.getParsedAndRemove("shortTitle")
		self.type       = try dictionary.getParsedAndRemove("type")
		self.category   = try dictionary.getParsedAndRemove("category")
		self.location   = try dictionary.getParsedIfExistsAndRemove("location")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

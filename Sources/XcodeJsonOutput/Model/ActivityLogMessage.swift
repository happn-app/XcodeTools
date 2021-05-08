import Foundation



struct ActivityLogMessage : _Object {

	static var type: ObjectType = .init(name: "ActivityLogMessage")
	
	var title: String
	var shortTitle: String
	
	var type: String
	var category: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let titleDic      = dictionary.removeValue(forKey: "title")      as? [String: Any?],
			let shortTitleDic = dictionary.removeValue(forKey: "shortTitle") as? [String: Any?],
			let typeDic       = dictionary.removeValue(forKey: "type")       as? [String: Any?],
			let categoryDic   = dictionary.removeValue(forKey: "category")   as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.title      = try .init(dictionary: titleDic)
		self.shortTitle = try .init(dictionary: shortTitleDic)
		self.type       = try .init(dictionary: typeDic)
		self.category   = try .init(dictionary: categoryDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

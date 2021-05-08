import Foundation



struct ActivityLogMessage : _Object {

	static var type: ObjectType = .init(name: "ActivityLogMessage")
	
	var title: String
	var shortTitle: String
	
	var type: String
	var category: String
	
	init(dictionary: [String : Any?]) throws {
		try Self.validateTypeFor(dictionary: dictionary)
		
		guard
			dictionary.count == 5,
			let titleDic      = dictionary["title"]      as? [String: Any?],
			let shortTitleDic = dictionary["shortTitle"] as? [String: Any?],
			let typeDic       = dictionary["type"]       as? [String: Any?],
			let categoryDic   = dictionary["category"]   as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.title      = try String(dictionary: titleDic)
		self.shortTitle = try String(dictionary: shortTitleDic)
		self.type       = try String(dictionary: typeDic)
		self.category   = try String(dictionary: categoryDic)
	}
	
}

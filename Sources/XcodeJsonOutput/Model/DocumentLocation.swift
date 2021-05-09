import Foundation



struct DocumentLocation : _Object {
	
	static var type: ObjectType = .init(name: "DocumentLocation")
	
	var concreteTypeName: String
	var url: URL
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.concreteTypeName = try dictionary.getParsedAndRemove("concreteTypeName")
		let urlString: String = try dictionary.getParsedAndRemove("url")
		
		guard let url = URL(string: urlString) else {
			throw Err.malformedObject
		}
		self.url = url
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

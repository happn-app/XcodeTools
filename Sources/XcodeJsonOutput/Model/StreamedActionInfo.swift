import Foundation



struct StreamedActionInfo : _Object {
	
	static var type: ObjectType = .init(name: "StreamedActionInfo")
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

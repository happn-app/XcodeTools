import Foundation



struct CodeCoverageInfo : _Object {
	
	static var type: ObjectType = .init(name: "CodeCoverageInfo")
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

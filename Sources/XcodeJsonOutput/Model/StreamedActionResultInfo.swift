import Foundation



struct StreamedActionResultInfo : _Object {
	
	static var type: ObjectType = .init(name: "StreamedActionResultInfo")
	
	var resultIndex: Int?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.resultIndex = try dictionary.getParsedIfExistsAndRemove("resultIndex")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

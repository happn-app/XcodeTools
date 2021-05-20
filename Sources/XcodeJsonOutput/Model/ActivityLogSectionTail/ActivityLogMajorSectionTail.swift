import Foundation



struct ActivityLogMajorSectionTail : _AnyActivityLogSectionTail {
	
	static var type: ObjectType = .init(name: "ActivityLogMajorSectionTail", supertype: .init(name: "ActivityLogSectionTail"))
	
	var duration: Double
	var result: String
	
	init(dictionary originalDictionary: [String : Any?], parentPropertyName: String?) throws {
		var dictionary = originalDictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary, parentPropertyName: parentPropertyName)
		
		self.duration = try dictionary.getParsedAndRemove("duration", originalDictionary)
		self.result   = try dictionary.getParsedAndRemove("result", originalDictionary)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

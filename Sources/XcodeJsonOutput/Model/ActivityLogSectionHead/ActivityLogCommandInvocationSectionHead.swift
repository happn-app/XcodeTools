import Foundation



struct ActivityLogCommandInvocationSectionHead : _AnyActivityLogSectionHead {
	
	static var type: ObjectType = .init(name: "ActivityLogCommandInvocationSectionHead", supertype: .init(name: "ActivityLogSectionHead"))
	
	var commandDetails: String
	
	var domainType: String
	var startTime: Date
	var title: String
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.commandDetails = try dictionary.getParsedAndRemove("commandDetails")
		
		self.domainType = try dictionary.getParsedAndRemove("domainType")
		self.startTime  = try dictionary.getParsedAndRemove("startTime")
		self.title      = try dictionary.getParsedAndRemove("title")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

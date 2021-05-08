import Foundation



struct ActionRunDestinationRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionRunDestinationRecord")
	
	var displayName: String
	var localComputerRecord: ActionDeviceRecord
	var targetArchitecture: String
	var targetDeviceRecord: ActionDeviceRecord
	var targetSDKRecord: ActionSDKRecord
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		self.displayName         = try dictionary.getParsedAndRemove("displayName")
		self.localComputerRecord = try dictionary.getParsedAndRemove("localComputerRecord")
		self.targetArchitecture  = try dictionary.getParsedAndRemove("targetArchitecture")
		self.targetDeviceRecord  = try dictionary.getParsedAndRemove("targetDeviceRecord")
		self.targetSDKRecord     = try dictionary.getParsedAndRemove("targetSDKRecord")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

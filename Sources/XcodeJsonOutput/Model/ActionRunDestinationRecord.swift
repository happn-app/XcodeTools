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
		
		guard
			let displayNameDic         = dictionary.removeValue(forKey: "displayName")         as? [String: Any?],
			let localComputerRecordDic = dictionary.removeValue(forKey: "localComputerRecord") as? [String: Any?],
			let targetArchitectureDic  = dictionary.removeValue(forKey: "targetArchitecture")  as? [String: Any?],
			let targetDeviceRecordDic  = dictionary.removeValue(forKey: "targetDeviceRecord")  as? [String: Any?],
			let targetSDKRecordDic     = dictionary.removeValue(forKey: "targetSDKRecord")     as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		self.displayName         = try .init(dictionary: displayNameDic)
		self.localComputerRecord = try .init(dictionary: localComputerRecordDic)
		self.targetArchitecture  = try .init(dictionary: targetArchitectureDic)
		self.targetDeviceRecord  = try .init(dictionary: targetDeviceRecordDic)
		self.targetSDKRecord     = try .init(dictionary: targetSDKRecordDic)
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

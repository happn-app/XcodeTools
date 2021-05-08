import Foundation



struct ActionDeviceRecord : _Object {
	
	static var type: ObjectType = .init(name: "ActionDeviceRecord")
	
	var busSpeedInMHz: Int?
	var cpuCount: Int?
	var cpuKind: String?
	var cpuSpeedInMHz: Int?
	var identifier: String
	var isConcreteDevice: Bool?
	var logicalCPUCoresPerPackage: Int?
	var modelCode: String
	var modelName: String
	var modelUTI: String
	var name: String
	var nativeArchitecture: String
	var operatingSystemVersion: String?
	var operatingSystemVersionWithBuildNumber: String?
	var physicalCPUCoresPerPackage: Int?
	var platformRecord: ActionPlatformRecord
	var ramSizeInMegabytes: Int?
	
	init(dictionary: [String : Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let identifierDic         = dictionary.removeValue(forKey: "identifier")         as? [String: Any?],
			let modelCodeDic          = dictionary.removeValue(forKey: "modelCode")          as? [String: Any?],
			let modelNameDic          = dictionary.removeValue(forKey: "modelName")          as? [String: Any?],
			let modelUTIDic           = dictionary.removeValue(forKey: "modelUTI")           as? [String: Any?],
			let nameDic               = dictionary.removeValue(forKey: "name")               as? [String: Any?],
			let nativeArchitectureDic = dictionary.removeValue(forKey: "nativeArchitecture") as? [String: Any?],
			let platformRecordDic     = dictionary.removeValue(forKey: "platformRecord")     as? [String: Any?]
		else {
			throw Err.malformedObject
		}
		
		let busSpeedInMHzDic:                         [String: Any?]? = try dictionary.getIfExistsAndRemove("busSpeedInMHz",                         wrongTypeError: Err.malformedObject)
		let cpuCountDic:                              [String: Any?]? = try dictionary.getIfExistsAndRemove("cpuCount",                              wrongTypeError: Err.malformedObject)
		let cpuKindDic:                               [String: Any?]? = try dictionary.getIfExistsAndRemove("cpuKind",                               wrongTypeError: Err.malformedObject)
		let cpuSpeedInMHzDic:                         [String: Any?]? = try dictionary.getIfExistsAndRemove("cpuSpeedInMHz",                         wrongTypeError: Err.malformedObject)
		let isConcreteDeviceDic:                      [String: Any?]? = try dictionary.getIfExistsAndRemove("isConcreteDevice",                      wrongTypeError: Err.malformedObject)
		let logicalCPUCoresPerPackageDic:             [String: Any?]? = try dictionary.getIfExistsAndRemove("logicalCPUCoresPerPackage",             wrongTypeError: Err.malformedObject)
		let operatingSystemVersionDic:                [String: Any?]? = try dictionary.getIfExistsAndRemove("operatingSystemVersion",                wrongTypeError: Err.malformedObject)
		let operatingSystemVersionWithBuildNumberDic: [String: Any?]? = try dictionary.getIfExistsAndRemove("operatingSystemVersionWithBuildNumber", wrongTypeError: Err.malformedObject)
		let physicalCPUCoresPerPackageDic:            [String: Any?]? = try dictionary.getIfExistsAndRemove("physicalCPUCoresPerPackage",            wrongTypeError: Err.malformedObject)
		let ramSizeInMegabytesDic:                    [String: Any?]? = try dictionary.getIfExistsAndRemove("ramSizeInMegabytes",                    wrongTypeError: Err.malformedObject)
		
		self.busSpeedInMHz                         = try busSpeedInMHzDic.flatMap{ try .init(dictionary: $0) }
		self.cpuCount                              = try cpuCountDic.flatMap{ try .init(dictionary: $0) }
		self.cpuKind                               = try cpuKindDic.flatMap{ try .init(dictionary: $0) }
		self.cpuSpeedInMHz                         = try cpuSpeedInMHzDic.flatMap{ try .init(dictionary: $0) }
		self.identifier                            = try .init(dictionary: identifierDic)
		self.isConcreteDevice                      = try isConcreteDeviceDic.flatMap{ try .init(dictionary: $0) }
		self.logicalCPUCoresPerPackage             = try logicalCPUCoresPerPackageDic.flatMap{ try .init(dictionary: $0) }
		self.modelCode                             = try .init(dictionary: modelCodeDic)
		self.modelName                             = try .init(dictionary: modelNameDic)
		self.modelUTI                              = try .init(dictionary: modelUTIDic)
		self.name                                  = try .init(dictionary: nameDic)
		self.nativeArchitecture                    = try .init(dictionary: nativeArchitectureDic)
		self.operatingSystemVersion                = try operatingSystemVersionDic.flatMap{ try .init(dictionary: $0) }
		self.operatingSystemVersionWithBuildNumber = try operatingSystemVersionWithBuildNumberDic.flatMap{ try .init(dictionary: $0) }
		self.physicalCPUCoresPerPackage            = try physicalCPUCoresPerPackageDic.flatMap{ try .init(dictionary: $0) }
		self.platformRecord                        = try .init(dictionary: platformRecordDic)
		self.ramSizeInMegabytes                    = try ramSizeInMegabytesDic.flatMap{ try .init(dictionary: $0) }
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

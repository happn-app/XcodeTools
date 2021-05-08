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
		
		self.identifier         = try dictionary.getParsedAndRemove("identifier")
		self.modelCode          = try dictionary.getParsedAndRemove("modelCode")
		self.modelName          = try dictionary.getParsedAndRemove("modelName")
		self.modelUTI           = try dictionary.getParsedAndRemove("modelUTI")
		self.name               = try dictionary.getParsedAndRemove("name")
		self.nativeArchitecture = try dictionary.getParsedAndRemove("nativeArchitecture")
		self.platformRecord     = try dictionary.getParsedAndRemove("platformRecord")
		
		self.busSpeedInMHz                         = try dictionary.getParsedIfExistsAndRemove("busSpeedInMHz")
		self.cpuCount                              = try dictionary.getParsedIfExistsAndRemove("cpuCount")
		self.cpuKind                               = try dictionary.getParsedIfExistsAndRemove("cpuKind")
		self.cpuSpeedInMHz                         = try dictionary.getParsedIfExistsAndRemove("cpuSpeedInMHz")
		self.isConcreteDevice                      = try dictionary.getParsedIfExistsAndRemove("isConcreteDevice")
		self.logicalCPUCoresPerPackage             = try dictionary.getParsedIfExistsAndRemove("logicalCPUCoresPerPackage")
		self.operatingSystemVersion                = try dictionary.getParsedIfExistsAndRemove("operatingSystemVersion")
		self.operatingSystemVersionWithBuildNumber = try dictionary.getParsedIfExistsAndRemove("operatingSystemVersionWithBuildNumber")
		self.physicalCPUCoresPerPackage            = try dictionary.getParsedIfExistsAndRemove("physicalCPUCoresPerPackage")
		self.ramSizeInMegabytes                    = try dictionary.getParsedIfExistsAndRemove("ramSizeInMegabytes")
		
		Self.logUnknownKeys(from: dictionary)
	}
	
}

import Foundation



public struct BuildSetting {
	
	public enum Location {
		
		/** For settings you don’t want written back anywhere. */
		case none
		case xcconfiguration(XCBuildConfiguration)
		case xcconfigFile(XCConfigRef, lineID: XCConfig.LineID)
		
	}
	
	public var key: BuildSettingKey
	public var value: Any
	
	public var location: Location
	
	public var stringValue: String {
		switch value {
			case let s as String:   return s
			case let a as [String]: return a.joined(separator: " ")
			default:
				NSLog("%@", "Asked string value of build setting whose value is \(value), which has type \(type(of: value)), which is not standard. Returning an empty String.")
				return ""
		}
	}
	
	public init(laxSerializedKey serializedKey: String, value v: Any, location l: Location, allowCommaSeparatorForParameters: Bool = false) {
		key = BuildSettingKey(laxSerializedKey: serializedKey, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters)
		value = v
		location = l
	}
	
	public init(key: BuildSettingKey, value: Any, location: Location) {
		self.key = key
		self.value = value
		self.location = location
	}
	
}


public typealias BuildSettingRef = Ref<BuildSetting>

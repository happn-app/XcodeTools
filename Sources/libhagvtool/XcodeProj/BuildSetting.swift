import Foundation



public struct BuildSetting {
	
	public var key: BuildSettingKey
	public var value: Any
	
	public var stringValue: String {
		switch value {
			case let s as String:   return s
			case let a as [String]: return a.joined(separator: " ")
			default:
				NSLog("%@", "Asked string value of build setting whose value is \(value), which has type \(type(of: value)), which is not standard. Returning an empty String.")
				return ""
		}
	}
	
	public init(laxSerializedKey serializedKey: String, value v: Any, allowCommaSeparatorForParameters: Bool = false) {
		key = BuildSettingKey(laxSerializedKey: serializedKey, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters)
		value = v
	}
	
	public init(key: BuildSettingKey, value: Any) {
		self.key = key
		self.value = value
	}
	
}

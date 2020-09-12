import Foundation



public struct BuildSetting {
	
	public var key: BuildSettingKey
	public var value: Any
	
	public init(laxSerializedKey serializedKey: String, value v: Any, allowCommaSeparatorForParameters: Bool = false) {
		key = BuildSettingKey(laxSerializedKey: serializedKey, allowCommaSeparatorForParameters: allowCommaSeparatorForParameters)
		value = v
	}
	
	public init(key: BuildSettingKey, value: Any) {
		self.key = key
		self.value = value
	}
	
}

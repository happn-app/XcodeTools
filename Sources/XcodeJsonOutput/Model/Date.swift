import Foundation



extension Date : _Object {
	
	static let type = ObjectType(name: "Date")
	
	init(dictionary originalDictionary: [String: Any?], parentPropertyName: String?) throws {
		var dictionary = originalDictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary, parentPropertyName: parentPropertyName)
		
		guard
			let valueStr = dictionary.removeValue(forKey: "_value") as? String,
			let value = Self.parser.date(from: valueStr)
		else {
			throw Err.invalidValueTypeOrMissingValue(parentPropertyName: parentPropertyName, expectedType: "Date", value: originalDictionary["_value"] as Any?)
		}
		
		self = value
		
		Self.logUnknownKeys(from: dictionary)
	}
	
	private static var parser: ISO8601DateFormatter = {
		let ret = ISO8601DateFormatter()
		ret.formatOptions = .withInternetDateTime
		ret.formatOptions.formUnion(.withFractionalSeconds)
		ret.formatOptions.subtract(.withColonSeparatorInTimeZone)
		return ret
	}()
	
}

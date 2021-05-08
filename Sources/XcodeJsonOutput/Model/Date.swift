import Foundation



extension Date : _Object {
	
	static let type = ObjectType(name: "Date")
	
	init(dictionary: [String: Any?]) throws {
		var dictionary = dictionary
		try Self.consumeAndValidateTypeFor(dictionary: &dictionary)
		
		guard
			let valueStr = dictionary.removeValue(forKey: "_value") as? String,
			let value = Self.parser.date(from: valueStr)
		else {
			throw Err.malformedObject
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

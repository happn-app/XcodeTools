import Foundation

import Utils



public enum Parser {
	
	public static func parse(jsonString: String) throws -> Object {
		return try self.parse(json: Data(jsonString.utf8))
	}
	
	public static func parse(json: Data) throws -> Object {
		let jsonObject = try Result{ try JSONSerialization.jsonObject(with: json, options: []) }
			.mapErrorAndGet{ Err.invalidJSON($0) }
		guard let dictionary = jsonObject as? [String: Any?] else {
			throw Err.invalidJSONType
		}
		return try self.parse(dictionary: dictionary)
	}
	
	public static func parse(dictionary: [String: Any?]) throws -> Object {
		let objectType = try ObjectType(dictionary: dictionary)
		for type: _Object.Type in [String.self, StreamedEvent.self] {
			guard objectType == type.type else {continue}
			return try type.init(dictionary: dictionary)
		}
		throw Err.unknownObjectType(objectType.name)
	}
	
}

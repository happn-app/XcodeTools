import Foundation



public enum Parser {
	
	public static func parse(jsonString: String) throws -> Object {
		return try self.parse(json: Data(jsonString.utf8))
	}
	
	public static func parse(json: Data) throws -> Object {
		// TODO: Catch error, map to own module error
		guard let dictionary = try JSONSerialization.jsonObject(with: json, options: []) as? [String: Any?] else {
			throw NSError()
		}
		return try self.parse(dictionary: dictionary)
	}
	
	public static func parse(dictionary: [String: Any?]) throws -> Object {
		let objectType = try ObjectType(dictionary: dictionary)
		for type: _Object.Type in [String.self, StreamedEvent.self] {
			guard objectType == type.type else {continue}
			return try type.init(dictionary: dictionary)
		}
		throw NSError() // Unknown object type
	}
	
}

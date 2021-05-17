import Foundation



/* Apparently supertype is only a String; we only have two levels in JSON output
 * from Xcode, never more (even in cases where we should). */
class ObjectType : Equatable, CustomStringConvertible {
	
	var name: String
	var supertype: ObjectType?
	
	init(name: String, supertype: ObjectType? = nil) {
		self.name = name
		self.supertype = supertype
	}
	
	convenience init(dictionary: [String: Any?]) throws {
		let typeDic: [String: Any?] = try dictionary.get("_type", notFoundError: Err.noObjectType, wrongTypeError: Err.malformedObjectType)
		try self.init(typeDictionary: typeDic)
	}
	
	convenience init(typeDictionary: [String: Any?]) throws {
		let name: String = try typeDictionary.get("_name", notFoundError: Err.malformedObjectType, wrongTypeError: Err.malformedObjectType)
		
		let supertype: ObjectType?
		if let supertypeDictionary: [String: Any?] = try typeDictionary.getIfExists("_supertype", wrongTypeError: Err.malformedObjectType) {
			guard typeDictionary.count == 2 else {
				throw Err.malformedObjectType
			}
			supertype = try ObjectType(typeDictionary: supertypeDictionary)
		} else {
			guard typeDictionary.count == 1 else {
				throw Err.malformedObjectType
			}
			supertype = nil
		}
		
		self.init(name: name, supertype: supertype)
	}
	
	var description: String {
		return "ObjectType<\(name)\((supertype.flatMap{ ", \($0)" } ?? ""))>"
	}
	
	static func ==(lhs: ObjectType, rhs: ObjectType) -> Bool {
		return lhs.name == rhs.name && lhs.supertype == rhs.supertype
	}
	
}

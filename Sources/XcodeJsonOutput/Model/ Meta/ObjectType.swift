import Foundation



class ObjectType : Equatable, CustomStringConvertible {
	
	var name: String
	var supertype: ObjectType?
	
	init(name: String, supertype: ObjectType? = nil) {
		self.name = name
		self.supertype = supertype
	}
	
	convenience init(dictionary: [String: Any?]) throws {
		guard let typeDic = dictionary["_type"] as? [String: Any?] else {
			throw Err.noObjectType
		}
		try self.init(typeDictionary: typeDic)
	}
	
	convenience init(typeDictionary: [String: Any?]) throws {
		guard let name = typeDictionary["_name"] as? String else {
			throw Err.malformedObjectType
		}
		let supertype: ObjectType?
		if let supertypeDictionary = typeDictionary["_supertype"] as? [String: Any?] {
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

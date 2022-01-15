import Foundation



public extension Dictionary {
	
	func get<T>(_ key: Key, notFoundError: @autoclosure () -> Error, wrongTypeError: @autoclosure () -> Error) throws -> T {
		guard let v = self[key] else {throw notFoundError()}
		guard let t = v as? T   else {throw wrongTypeError()}
		return t
	}
	
	func getIfExists<T>(_ key: Key, wrongTypeError: @autoclosure () -> Error) throws -> T? {
		guard let v = self[key] else {return nil}
		guard let t = v as? T   else {throw wrongTypeError()}
		return t
	}
	
	mutating func getAndRemove<T>(_ key: Key, notFoundError: @autoclosure () -> Error, wrongTypeError: @autoclosure () -> Error) throws -> T {
		let v: T = try get(key, notFoundError: notFoundError(), wrongTypeError: wrongTypeError())
		removeValue(forKey: key)
		return v
	}
	
	mutating func getIfExistsAndRemove<T>(_ key: Key, wrongTypeError: @autoclosure () -> Error) throws -> T? {
		let v: T? = try getIfExists(key, wrongTypeError: wrongTypeError())
		removeValue(forKey: key)
		return v
	}
	
}


public extension Dictionary where Value : Equatable {
	
	/**
	 Same as `merging(_:, uniquingKeysWith:)`, but other dictionary must be fully distinct
	 from client (set of keys is distinct) or value must be the same for the same keys,
	 otherwise you get a crash.
	 
	 - Note: Requires `Value` of the `Dictionary` to be `Equatable` only
	 to be able to check if values are equal in case of same key in two dictionaries. */
	func mergingUnambiguous(_ other: [Key: Value]) -> [Key: Value] {
		return merging(other, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			return current
		})
	}
	
}

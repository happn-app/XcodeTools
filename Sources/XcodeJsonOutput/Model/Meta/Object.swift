import Foundation



public protocol Object {
	
}

protocol _Object : Object {
	
	static var type: ObjectType {get}
	init(dictionary: [String: Any?]) throws
	
}

extension _Object {
	
	/**
	Convenience one can call at start of concrete init implementations to
	validate the type of the dictionary that has been passed in. */
	static func validateTypeFor(dictionary: [String: Any?]) throws {
		guard try ObjectType(dictionary: dictionary) == Self.type else {
			throw NSError() // Internal error probably
		}
	}
	
}

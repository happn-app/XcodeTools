import Foundation



public extension Optional {
	
	func get(orThrow nilError: Error) throws -> Wrapped {
		guard let v = self else {
			throw nilError
		}
		return v
	}
	
}

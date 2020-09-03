import Foundation



extension Collection {
	
	public var onlyElement: Element? {
		guard let e = first, count == 1 else {
			return nil
		}
		return e
	}
	
}


extension Dictionary {
	
	func get<T>(_ key: Key) throws -> T {
		guard let e = self[key] else {
			throw HagvtoolError(message: "Value not found for key \(key)")
		}
		guard let t = e as? T else {
			throw HagvtoolError(message: "Value does not have correct type for key \(key)")
		}
		return t
	}
	
}

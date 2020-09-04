import CoreData
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


extension NSManagedObjectContext {
	
	/* Should be declared as rethrows instead of throws, but did not find a way
	 * to do it sadly. */
	func performAndWait<T>(_ block: () throws -> T) throws -> T {
		var ret: T?
		var err: Error?
		performAndWait{
			do    {ret = try block()}
			catch {err = error}
		}
		if let e = err {throw e}
		return ret!
	}
	
}


extension NSEntityDescription {
	
	func topmostSuperentity() -> NSEntityDescription {
		if let s = superentity {
			return s.topmostSuperentity()
		}
		return self
	}
	
}

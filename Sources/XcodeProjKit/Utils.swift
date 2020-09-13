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
			throw XcodeProjKitError(message: "Value not found for key \(key)")
		}
		guard let t = e as? T else {
			throw XcodeProjKitError(message: "Value does not have correct type for key \(key)")
		}
		return t
	}
	
	func getIfExists<T>(_ key: Key) throws -> T? {
		guard let e = self[key] else {
			return nil
		}
		guard let t = e as? T else {
			throw XcodeProjKitError(message: "Value does not have correct type for key \(key)")
		}
		return t
	}
	
}


public extension NSManagedObjectContext {
	
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


extension Scanner {
	
	convenience init(forParsing string: String) {
		self.init(string: string)
		
		locale = nil
		caseSensitive = true
		charactersToBeSkipped = CharacterSet()
	}
	
}

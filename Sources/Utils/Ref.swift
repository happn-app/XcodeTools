import Foundation



/**
Basically, a pointer.

This allows to wrap a struct to be able to use the same instance in more than
one place. */
public class Ref<T> {
	
	public var value: T
	
	public init(_ v: T) {
		value = v
	}
	
}


extension Ref : Equatable where T : Equatable {
	
	public static func ==(_ lhs: Ref<T>, _ rhs: Ref<T>) -> Bool {
		return lhs.value == rhs.value
	}
	
}


extension Ref : Hashable where T : Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(value)
	}
	
}

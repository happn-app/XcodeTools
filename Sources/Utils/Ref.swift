import Foundation



/**
 Basically, a pointer.
 
 This allows to wrap a struct to be able to use the same instance in more than one place.
 
 - Important: Two `Ref`s are equatable if the referenced type is equatable,
 and are considered equal iif _their referenced object is equal_.
 Be careful if you use this class in a Set for instance:
 you _must not_ mutate the Ref while it is in the set or you might break unicity contraint of the Set. */
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

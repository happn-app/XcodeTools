import Foundation



public extension Error {
	
	/**
	Throws itself.
	
	This is useful in certain workflows where you have an optional error and want
	to throw it if it is non-nil.
	
	````
	var err: Error?
	while logic {do {} catch {err = error; break}}
	someCleanupThatCantBeDoneInCatchClause()
	try err?.throw()
	...
	```` */
	func `throw`(_ wrapped: (Self) -> Error = { $0 }) throws {
		throw wrapped(self)
	}
	
}

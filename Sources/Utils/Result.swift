import Foundation



public extension Result {
	
	func mapErrorAndGet<NewFailure>(_ transform: (Failure) -> NewFailure) throws -> Success where NewFailure : Error {
		return try mapError(transform).get()
	}
	
}

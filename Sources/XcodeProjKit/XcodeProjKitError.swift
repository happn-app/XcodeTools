import Foundation



public struct XcodeProjKitError : Error {
	
	public var message: String
	
	public init(message msg: String) {
		message = msg
	}
	
	public var localizedDescription: String {
		return message
	}
	
}

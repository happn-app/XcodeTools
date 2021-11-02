import Foundation



public struct XctGenError : Error {
	
	public var message: String
	
	public init(message msg: String) {
		message = msg
	}
	
	public var localizedDescription: String {
		return message
	}
	
}

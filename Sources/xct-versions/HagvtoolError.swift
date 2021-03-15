import Foundation



public struct HagvtoolError : Error {
	
	public var message: String
	
	public init(message msg: String) {
		message = msg
	}
	
	public var localizedDescription: String {
		return message
	}
	
}

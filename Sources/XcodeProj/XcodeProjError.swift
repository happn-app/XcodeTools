import Foundation



public enum XcodeProjError : Error {
	
	case parseError(ParseError, objectID: String? /* nil if unknown */)
	
	public enum ParseError : Error {
		
		case unexpectedPropertyValue(propertyName: String, value: String)
		
	}
	
	#warning("Line below exists just so the project compiles. Must be removed.")
	init(message: String) {
		self = .parseError(ParseError.unexpectedPropertyValue(propertyName: "", value: ""), objectID: nil)
	}
	
}

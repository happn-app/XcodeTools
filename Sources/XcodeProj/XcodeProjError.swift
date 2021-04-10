import Foundation



public enum XcodeProjError : Error {
	
	case parseError(ParseError, objectID: String? /* nil if unknown */)
	case serializationError(SerializationError, objectID: String? /* nil if unknown */)
	
	public enum ParseError : Error {
		
		case missingProperty(propertyName: String)
		case unexpectedPropertyValueType(propertyName: String, value: Any)
		
		case unknownOrInvalidProjectReference([String: String])
		
		case invalidIntString(propertyName: String, string: String)
		case invalidURLString(propertyName: String, string: String)
		
	}
	
	public enum SerializationError : Error {
		
		case missingProperty(propertyName: String)
		
	}
	
	#warning("Line below exists just so the project compiles. Must be removed.")
	init(message: String) {
		self = .parseError(ParseError.unexpectedPropertyValueType(propertyName: "", value: ""), objectID: nil)
	}
	
}

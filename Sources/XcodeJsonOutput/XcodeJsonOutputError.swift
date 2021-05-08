import Foundation



public enum XcodeJsonOutputError : Error {
	
	case invalidJSON(Error)
	case invalidJSONType
	
	case noObjectType
	case malformedObjectType
	
	/**
	When trying to init an object with a dictionary whose type is incompatible. */
	case invalidObjectType
	case malformedObject
	
	case unknownObjectType(String)
	
}

typealias Err = XcodeJsonOutputError

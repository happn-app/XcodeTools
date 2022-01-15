import Foundation



/** All of the errors thrown by the module should have this type. */
public enum SPMProjError : Error {
	
	case cannotLoadPackage(URL/*, spmError: Error */)
	
}

typealias Err = SPMProjError

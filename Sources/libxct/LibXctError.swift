import Foundation

import SystemPackage



public enum LibXctError : Error {
	
	/**
	Some methods need `XCT_EXEC_PATH` to be set and throw this error if it is not. */
	case envVarXctExecPathNotSet
	
	/**
	When trying to register a new handler for a signal, if the sigaction has been
	detected to have been changed, this error is thrown. */
	case signalHandlerChangedOutOfLib
	
	case systemError(Errno)
	case internalError(String)
	
}

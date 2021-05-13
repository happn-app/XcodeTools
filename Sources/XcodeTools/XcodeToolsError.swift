import Foundation

import SystemPackage



public enum XcodeToolsError : Error {
	
	/**
	Some methods need `XCT_EXEC_PATH` to be set and throw this error if it is not. */
	case envVarXctExecPathNotSet
	
	case systemError(Errno)
	case internalError(String)
	
}

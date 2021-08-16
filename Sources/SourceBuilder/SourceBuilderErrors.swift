import Foundation

import SystemPackage



enum SourceBuilderError : Error {
	
	case unknownVariablesInURLTemplate(Set<String>)
	case invalidURL(String)
	case invalidURLResponse(URLResponse)
	case invalidChecksumForDownloadedFile(URL, String)
	
	/* Also open error to handle… */
//	case urlSessionError(Error)
	case notImplemented
	
}

typealias Err = SourceBuilderError

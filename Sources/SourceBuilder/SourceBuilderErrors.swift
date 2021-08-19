import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import SystemPackage



enum SourceBuilderError : Error {
	
	case unknownVariablesInURLTemplate(Set<String>)
	case invalidURL(String)
	case invalidURLResponse(URLResponse)
	case invalidChecksumForDownloadedFile(URL, String)
	
	case filepathHasNoExtensions(FilePath)
	case filepathHasNoStem(FilePath)

	/* Also open error to handle… */
//	case urlSessionError(Error)
	case unknownNetworkingError /* We should not need that one once Linux has support for async/await */
	case notImplemented
	
}

typealias Err = SourceBuilderError

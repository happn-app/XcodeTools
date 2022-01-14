import CoreData
import Foundation

import SPMProj



extension XcodeProj {
	
	/**
	 Finds file reference of type “wrapper” in the project.
	 If the wrapper is a valid SPM package (an ``SPMProj`` object can be created from the URL), it is passed to you in the handler. */
	public func iterateSPMPackagesInReferencedFile(_ handler: (_ proj: SPMProj) -> Void) throws {
		try iterateReferencedFiles{ url, type in
			guard type == "wrapper" else {return}
			guard let spmProj = try? SPMProj(url: url) else {
				Conf.logger?.info("Found invalid SPM project at path \(url.path) in project at path \(xcodeprojURL.path)")
				return
			}
			handler(spmProj)
		}
	}
	
}

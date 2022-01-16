import CoreData
import Foundation



extension XcodeProj {
	
	public func iterateReferencedFiles(_ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		try managedObjectContext.performAndWait{
			try unsafeIterateReferencedFiles(handler)
		}
	}
	
	public func iterateSources(of targetName: String, _ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		try managedObjectContext.performAndWait{
			for target in try pbxproj.rootObject.getTargets().filter({ try $0.getName() == targetName }) {
				for buildPhase in try target.getBuildPhases().compactMap({ $0 as? PBXSourcesBuildPhase }) {
					try unsafeIterateFileElementsForFiles(fileElements: buildPhase.getFiles().compactMap{ $0.fileRef }, handler)
				}
			}
		}
	}
	
	internal func unsafeIterateReferencedFiles(_ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		try unsafeIterateFileElementsForFiles(fileElements: pbxproj.rootObject.getMainGroup().getChildren(), handler)
	}
	
	private func unsafeIterateFileElementsForFiles(fileElements: [PBXFileElement], _ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		for fileElement in fileElements {
			switch fileElement {
				case let fileRef as PBXFileReference:
					let url = try fileRef.resolvedPathAsURL(xcodeprojURL: xcodeprojURL, variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: xcodeprojURL))
					handler(url, fileRef.lastKnownFileType)
					
				case let group as PBXGroup:
					try unsafeIterateFileElementsForFiles(fileElements: group.getChildren(), handler)
					
				case let refProxy as PBXReferenceProxy:
					let url = try refProxy.resolvedPathAsURL(xcodeprojURL: xcodeprojURL, variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: xcodeprojURL))
					try handler(url, refProxy.getFileType())
					
				case let variantGroup as PBXVariantGroup:
					try unsafeIterateFileElementsForFiles(fileElements: variantGroup.getChildren(), handler)
					
				case let versionGroup as XCVersionGroup:
					try unsafeIterateFileElementsForFiles(fileElements: versionGroup.getChildren(), handler)
					
				default:
					throw Err.internalError(.unknownFileElementClass(rawISA: fileElement.rawISA))
			}
		}
	}
	
}

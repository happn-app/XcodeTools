import CoreData
import Foundation



public extension XcodeProj {
	
	func iterateFiles(_ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		try managedObjectContext.performAndWait{
			try unsafeIterateFileElementsForFiles(fileElements: pbxproj.rootObject.getMainGroup().getChildren(), handler)
		}
	}
	
	private func unsafeIterateFileElementsForFiles(fileElements: [PBXFileElement], _ handler: (_ fileURL: URL, _ knownFileType: String?) -> Void) throws {
		for fileElement in fileElements {
			switch fileElement {
				case let fileRef as PBXFileReference:
					let url = try fileRef.resolvedPathAsURL(xcodeprojURL: xcodeprojURL, variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: xcodeprojURL))
					handler(url, fileRef.lastKnownFileType)
					print(fileRef)
					print(fileRef.buildFiles_?.map{ $0 })
					
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

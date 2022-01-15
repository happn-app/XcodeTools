import CoreData
import Foundation

import SPMProj
import XcodeProj



public enum Target {
	
	case xcodeTarget(targetID: NSManagedObjectID, context: NSManagedObjectContext, xcodeprojURL: URL)
	case spmTarget(SPMTarget)
	
	public var isSPMTarget: Bool {
		switch self {
			case .xcodeTarget: return false
			case .spmTarget:   return true
		}
	}
	
	public func getName() throws -> String {
		switch self {
			case let .xcodeTarget(targetID: targetID, context: context, xcodeprojURL: _):
				return try context.performAndWait{
					return try unsafeXcodeTargetFromID(targetID, context: context).getName()
				}
				
			case let .spmTarget(spmTarget):
				return spmTarget.name
		}
	}
	
	public func getSourcesRoot() -> URL? {
		switch self {
			case     .xcodeTarget:          return nil
			case let .spmTarget(spmTarget): return spmTarget.sourcesRoot
		}
	}
	
	public func getSources() throws -> [URL] {
		switch self {
			case let .xcodeTarget(targetID: targetID, context: context, xcodeprojURL: xcodeprojURL):
				return try context.performAndWait{
					return try unsafeXcodeTargetFromID(targetID, context: context)
						.getBuildPhases()
						.lazy
						.compactMap{ $0 as? PBXSourcesBuildPhase }
						.flatMap{ sourcesPhase in
							try sourcesPhase.getFiles().compactMap{ file in
								/* A build file has either a file ref or a product ref. */
								return try file.fileRef?.resolvedPathAsURL(
									xcodeprojURL: xcodeprojURL,
									variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: xcodeprojURL)
								)
							}
						}
				}
				
			case let .spmTarget(spmTarget):
				return spmTarget.sources
		}
	}
	
	public func getResources() throws -> [URL] {
		switch self {
			case let .xcodeTarget(targetID: targetID, context: context, xcodeprojURL: xcodeprojURL):
				return try context.performAndWait{
					return try unsafeXcodeTargetFromID(targetID, context: context)
						.getBuildPhases()
						.lazy
						.compactMap{ $0 as? PBXResourcesBuildPhase }
						.flatMap{ sourcesPhase in
							try sourcesPhase.getFiles().compactMap{ file in
								/* A build file has either a file ref or a product ref. */
								return try file.fileRef?.resolvedPathAsURL(
									xcodeprojURL: xcodeprojURL,
									variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: xcodeprojURL)
								)
							}
						}
				}
				
			case let .spmTarget(spmTarget):
				return spmTarget.resources
		}
	}
	
	private func unsafeXcodeTargetFromID(_ targetID: NSManagedObjectID, context: NSManagedObjectContext) throws -> PBXTarget {
		guard let target = try context.existingObject(with: targetID) as? PBXTarget else {
			throw Err.internalError("Invalid target ID whose linked object is not kind of PBXTarget.")
		}
		return target
	}
	
}

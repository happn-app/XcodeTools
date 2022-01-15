import Foundation

import SPMProj
import XcodeProj



public enum Project {
	
	case xcodeproj(XcodeProj)
//	case xcworkspace(XcodeWorkspace)
	case spm(SPMProj)
	
	public init(xcodeprojPath: String?, autodetectInFolderAtPath autodetectFolder: String = ".") throws {
		try self = .xcodeproj(XcodeProj(path: xcodeprojPath, autodetectInFolderAtPath: autodetectFolder))
	}
	
	public init(xcodeprojURL: URL) throws {
		try self = .xcodeproj(XcodeProj(xcodeprojURL: xcodeprojURL))
	}
	
	public func getTargets() throws -> [Target] {
		switch self {
			case .xcodeproj(let proj):
				var res = [Target]()
				try proj.managedObjectContext.performAndWait{
					res.append(contentsOf: try proj.pbxproj.rootObject.getTargets().map{ target in
						.xcodeTarget(targetID: target.objectID, context: proj.managedObjectContext, xcodeprojURL: proj.xcodeprojURL)
					})
				}
				try proj.iterateSPMPackagesInReferencedFile{ spm in
					res.append(contentsOf: spm.targets.map{ .spmTarget($0) })
				}
				return res
				
			case .spm(let spm):
				return spm.targets.map{ .spmTarget($0) }
		}
	}
	
}

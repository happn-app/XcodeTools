import Foundation

import SPMProj
import XcodeProj



public enum Project {
	
	case xcodeproj(XcodeProj)
//	case xcworkspace(XcodeWorkspace)
	case spm(SPMProj)
	
	public init(xcodeprojURL: URL) throws {
		try self = .xcodeproj(XcodeProj(xcodeprojURL: xcodeprojURL))
	}
	
	public var targets: [Target] {
		get throws {
			switch self {
				case .xcodeproj(let proj):
					var res = [Target]()
					try proj.managedObjectContext.performAndWait{
						for target in try proj.pbxproj.rootObject.getTargets() {
							let name = try target.getName()
							var sources = [URL]()
							var resources = [URL]()
							for buildPhase in try target.getBuildPhases() {
								switch buildPhase {
									case let sourcesPhase as PBXSourcesBuildPhase:
										for file in try sourcesPhase.getFiles() {
											/* A build file has either a file ref or a product ref. */
											guard let url = try file.fileRef?.resolvedPathAsURL(
												xcodeprojURL: proj.xcodeprojURL,
												variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: proj.xcodeprojURL)
											) else {
												continue
											}
											sources.append(url)
										}
										
									case let resPhase as PBXResourcesBuildPhase:
										for file in try resPhase.getFiles() {
											guard let url = try file.fileRef?.resolvedPathAsURL(
												xcodeprojURL: proj.xcodeprojURL,
												variables: BuildSettings.standardDefaultSettingsForResolvingPathsAsDictionary(xcodprojURL: proj.xcodeprojURL)
											) else {
												continue
											}
											resources.append(url)
										}
										
									default:
										(/*TODO: Do we need these files?*/)
								}
							}
							res.append(Target(name: name, sources: sources, resources: resources))
						}
					}
					try proj.iterateSPMPackagesInReferencedFile{ spm in
						res.append(contentsOf: spm.targets.map{ Target(name: $0.name, sources: $0.sources, resources: $0.resources) })
					}
					return res
					
				case .spm(let spm):
					return spm.targets.map{ Target(name: $0.name, sources: $0.sources, resources: $0.resources) }
			}
		}
	}
	
}

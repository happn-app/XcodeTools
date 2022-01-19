import Foundation

import ArgumentParser
import XcodeProj



struct Sanitize : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Sanitize a pbxproj.",
		discussion: """
			Actions for the whole project:
			   - Sort the packages dependencies.
			
			Actions for each targets:
			   - Make implicit dependencies from linked Swift Packages explicit;
			   - Sort the build files in the build phases.
			"""
	)
	
	@OptionGroup
	var xctPbxprojOptions: XctPbxproj.Options
	
	func run() throws {
		XctPbxproj.bootstrap()
		let logger = XctPbxproj.logger
		
		
		let xcodeproj = try XcodeProj(path: xctPbxprojOptions.pathToXcodeproj)
		let context = xcodeproj.managedObjectContext
		try context.performAndWait{
			var modified = false
			
			/* Sort the package references. */
			let ids = xcodeproj.pbxproj.rootObject.packageReferences?.map{ $0.objectID }
			try xcodeproj.pbxproj.rootObject.packageReferences = xcodeproj.pbxproj.rootObject.packageReferences?.sorted{ ref1, ref2 in
				try ref1.retrievePackageName().localizedCaseInsensitiveCompare(ref2.retrievePackageName()) == .orderedAscending
			}
			modified = (modified || ids != xcodeproj.pbxproj.rootObject.packageReferences?.map{ $0.objectID })
			
			/* Make all dependencies from framework build phase explicit. */
#warning("TODO")
			
			/* Sort the build files in the build phases. */
			try xcodeproj.pbxproj.rootObject.getTargets().forEach{ target in
				target.buildPhases?.forEach{ buildPhase in
					let ids = buildPhase.files?.map{ $0.objectID }
					buildPhase.files = buildPhase.files?.sorted{ buildFile1, buildFile2 in
						(buildFile1.itemName ?? "").localizedCaseInsensitiveCompare(buildFile2.itemName ?? "") == .orderedAscending
					}
					modified = (modified || ids != buildPhase.files?.map{ $0.objectID })
				}
			}
			
			try context.save()
			if modified {
				logger.info("Rewriting pbxproj")
				try Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8).write(to: xcodeproj.pbxprojURL)
			} else {
				logger.info("pbxproj is left unmodified")
			}
		}
	}
	
}

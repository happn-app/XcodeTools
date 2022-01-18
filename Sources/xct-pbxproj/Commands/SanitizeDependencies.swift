import Foundation

import ArgumentParser
import XcodeProj



struct SanitizeDependencies : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		commandName: "sanitize-dependencies",
		abstract: "Sanitize dependencies in a pbxproj.",
		discussion: """
			Actions for the whole project:
			   - Sort the packages dependencies.
			
			Actions for each targets:
			   - Make implicit dependencies from linked Swift Packages explicit;
			   - Sort the dependencies and linked frameworks.
			"""
	)
	
	@OptionGroup
	var xctPbxprojOptions: XctPbxproj.Options
	
	func run() throws {
		XctPbxproj.bootstrap()
//		let logger = XctPbxproj.logger
		
		let xcodeproj = try XcodeProj(path: xctPbxprojOptions.pathToXcodeproj)
		let context = xcodeproj.managedObjectContext
		try context.performAndWait{
			var err: Error?
			xcodeproj.pbxproj.rootObject.packageReferences_cd = (xcodeproj.pbxproj.rootObject.packageReferences_cd?.sortedArray{ ref1, ref2 in
				guard err == nil else {
					return .orderedSame
				}
				guard let ref1 = ref1 as? XCRemoteSwiftPackageReference else {
					err = Err(message: "Unknown ref type: \(ref1)")
					return .orderedSame
				}
				guard let ref2 = ref2 as? XCRemoteSwiftPackageReference else {
					err = Err(message: "Unknown ref type: \(ref2)")
					return .orderedSame
				}
				let name1 = ref1.repositoryURL?.deletingPathExtension().lastPathComponent ?? ""
				let name2 = ref2.repositoryURL?.deletingPathExtension().lastPathComponent ?? ""
				return name1.localizedCaseInsensitiveCompare(name2)
			}).flatMap{ NSOrderedSet(array: $0) }
			if context.hasChanges {
				try context.save()
				try Data(xcodeproj.pbxproj.stringSerialization(projectName: xcodeproj.projectName).utf8).write(to: xcodeproj.pbxprojURL)
			}
		}
	}
	
}

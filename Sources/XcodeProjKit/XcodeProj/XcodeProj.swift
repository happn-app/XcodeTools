import CoreData
import Foundation



public struct XcodeProj {
	
	public let xcodeprojURL: URL
	public let pbxprojURL: URL
	
	public let pbxproj: PBXProj
	
	public let persistentCoordinator: NSPersistentStoreCoordinator
	
	public let managedObjectModel: NSManagedObjectModel
	public let managedObjectContext: NSManagedObjectContext
	
	public init(path: String? = nil, autodetectFolder: String = ".") throws {
		let xcodeprojPath: String
		if let p = path {
			xcodeprojPath = p
		} else {
			let fm = FileManager.default
			let xcodeprojs = try fm.contentsOfDirectory(atPath: autodetectFolder).filter{
				var isDir = ObjCBool(false)
				guard $0.hasSuffix(".xcodeproj") else {return false}
				guard fm.fileExists(atPath: $0, isDirectory: &isDir), isDir.boolValue else {return false}
				guard fm.fileExists(atPath: $0.appending("/project.pbxproj"), isDirectory: &isDir), !isDir.boolValue else {return false}
				return true
			}
			guard let e = xcodeprojs.onlyElement else {
				throw XcodeProjKitError(message: "Cannot find xcodeproj")
			}
			xcodeprojPath = e
		}
		
		xcodeprojURL = URL(fileURLWithPath: xcodeprojPath, isDirectory: true)
		pbxprojURL = xcodeprojURL.appendingPathComponent("project.pbxproj", isDirectory: false)
		
		
		/* *** Load CoreData model *** */
		
		guard let modelURL = Bundle.module.url(forResource: "PBXModel", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw XcodeProjKitError(message: "Cannot load CoreData model")
		}
		managedObjectModel = model
		
		persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		try persistentCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		
		managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentCoordinator
		
		pbxproj = try PBXProj(url: pbxprojURL, context: managedObjectContext)
	}
	
	public func iterateCombinedBuildSettingsOfTargets(_ handler: (_ target: PBXTarget, _ targetName: String, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> Void) throws {
		let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
		try iterateCombinedBuildSettingsOfTargets(defaultBuildSettings: defaultBuildSettings, handler)
	}
	
	public func iterateCombinedBuildSettingsOfTargets(defaultBuildSettings: BuildSettings, _ handler: (_ target: PBXTarget, _ targetName: String, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> Void) throws {
		try managedObjectContext.performAndWait{
			let pbxProject = pbxproj.rootObject
			let allCombinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: pbxProject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			
			try allCombinedBuildSettings.sorted(by: CombinedBuildSettings.convenienceSort).map{ combinedBuildSettings -> (PBXTarget, String, String, CombinedBuildSettings) in
				guard let targetName = combinedBuildSettings.targetName else {
					throw XcodeProjKitError(message: "Internal error: Got combined build settings for target which does not have a target name.")
				}
				guard let targetID = combinedBuildSettings.targetID, let targetObject = try? managedObjectContext.existingObject(with: targetID), let target = targetObject as? PBXTarget else {
					throw XcodeProjKitError(message: "Internal error: Got combined build settings for target which does not have a target ID, or whose target does not exist for the given ID anymore.")
				}
				return (target, targetName, combinedBuildSettings.configurationName, combinedBuildSettings)
			}.forEach{ e in
				try handler(e.0, e.1, e.2, e.3)
			}
		}
	}
	
}

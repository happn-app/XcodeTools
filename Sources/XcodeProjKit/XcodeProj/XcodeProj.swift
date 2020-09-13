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
	
	public func iterateCombinedBuildSettings(_ handler: () throws -> Void) throws {
		let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
		try iterateCombinedBuildSettings(defaultBuildSettings: defaultBuildSettings, handler)
	}
	
	public func iterateCombinedBuildSettings(defaultBuildSettings: BuildSettings, _ handler: (_ targetName: String, configurationName: String, _ combinedBuildSettings: CombinedBuildSettings, _ target: PBXTarget) throws -> Void) throws {
		try managedObjectContext.performAndWait{
			let pbxProject = pbxproj.rootObject
			let allCombinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: pbxProject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			
			
			for (targetName, configurationNameAndBuildSettings) in allCombinedBuildSettings.sorted(by: { $0.key < $1.key }) {
				guard let target = pbxProject.targets?.filter({ $0.name == targetName }).onlyElement else {
					throw XcodeProjKitError(message: "Internal error: Cannot find the target by name when iterating combined build configs (either got mutliple targets w/ the same name or no target w/ the given name)")
				}
				
				for (configurationName, combinedBuildSettings) in configurationNameAndBuildSettings.sorted(by: { $0.key < $1.key }) {
				}
			}
		}
	}
	
}

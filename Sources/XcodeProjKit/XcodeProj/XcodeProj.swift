import CoreData
import Foundation



public struct XcodeProj {
	
	public let xcodeprojURL: URL
	public let pbxprojURL: URL
	
	public let pbxproj: PBXProj
	
	public let persistentCoordinator: NSPersistentStoreCoordinator
	
	public let managedObjectModel: NSManagedObjectModel
	public let managedObjectContext: NSManagedObjectContext
	
	public init(path: String? = nil, autodetectInFolderAtPath: String = ".") throws {
		let xcodeprojPath: String
		if let p = path {
			xcodeprojPath = p
		} else {
			let fm = FileManager.default
			let xcodeprojs = try fm.contentsOfDirectory(atPath: autodetectInFolderAtPath).filter{
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
		
		try self.init(xcodeprojURL: URL(fileURLWithPath: xcodeprojPath, isDirectory: true))
	}
	
	public init(xcodeprojURL url: URL) throws {
		xcodeprojURL = url
		pbxprojURL = xcodeprojURL.appendingPathComponent("project.pbxproj", isDirectory: false)
		
		/* *** Load CoreData model *** */
		
		guard let model = ModelSingleton.model else {
			throw XcodeProjKitError(message: "Cannot load CoreData model")
		}
		managedObjectModel = model
		
		persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		try persistentCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		
		managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentCoordinator
		
		pbxproj = try PBXProj(url: pbxprojURL, context: managedObjectContext)
	}
	
	public var projectName: String {
		return xcodeprojURL.deletingPathExtension().lastPathComponent
	}
	
	@discardableResult
	public func iterateCombinedBuildSettingsOfProject<T>(_ handler: (_ configuration: XCBuildConfiguration, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> T) throws -> [T] {
		let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
		return try iterateCombinedBuildSettingsOfProject(defaultBuildSettings: BuildSettingsRef(defaultBuildSettings), handler)
	}
	
	@discardableResult
	public func iterateCombinedBuildSettingsOfTargets<T>(_ handler: (_ target: PBXTarget, _ targetName: String, _ configuration: XCBuildConfiguration, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> T) throws -> [T] {
		let defaultBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL)
		return try iterateCombinedBuildSettingsOfTargets(defaultBuildSettings: BuildSettingsRef(defaultBuildSettings), handler)
	}
	
	@discardableResult
	public func iterateCombinedBuildSettingsOfProject<T>(defaultBuildSettings: BuildSettingsRef, _ handler: (_ configuration: XCBuildConfiguration, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> T) throws -> [T] {
		return try managedObjectContext.performAndWait{
			let pbxProject = pbxproj.rootObject
			let allCombinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForProject(pbxProject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			
			return try allCombinedBuildSettings.sorted(by: CombinedBuildSettings.convenienceSort).map{ combinedBuildSettings -> T in
				guard combinedBuildSettings.targetName == nil else {
					throw XcodeProjKitError(message: "Internal error: Got combined build settings for project which has a target name.")
				}
				return try handler(combinedBuildSettings.configuration, combinedBuildSettings.configurationName, combinedBuildSettings)
			}
		}
	}
	
	@discardableResult
	public func iterateCombinedBuildSettingsOfTargets<T>(defaultBuildSettings: BuildSettingsRef, _ handler: (_ target: PBXTarget, _ targetName: String, _ configuration: XCBuildConfiguration, _ configurationName: String, _ combinedBuildSettings: CombinedBuildSettings) throws -> T) throws -> [T] {
		return try managedObjectContext.performAndWait{
			let pbxProject = pbxproj.rootObject
			let allCombinedBuildSettings = try CombinedBuildSettings.allCombinedBuildSettingsForTargets(of: pbxProject, xcodeprojURL: xcodeprojURL, defaultBuildSettings: defaultBuildSettings)
			
			return try allCombinedBuildSettings.sorted(by: CombinedBuildSettings.convenienceSort).map{ combinedBuildSettings -> T in
				guard let targetName = combinedBuildSettings.targetName else {
					throw XcodeProjKitError(message: "Internal error: Got combined build settings for target which does not have a target name.")
				}
				guard let target = combinedBuildSettings.target else {
					throw XcodeProjKitError(message: "Internal error: Got combined build settings for target which does not have a target.")
				}
				return try handler(target, targetName, combinedBuildSettings.configuration, combinedBuildSettings.configurationName, combinedBuildSettings)
			}
		}
	}
	
}

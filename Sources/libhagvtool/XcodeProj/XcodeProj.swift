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
				throw HagvtoolError(message: "Cannot find xcodeproj")
			}
			xcodeprojPath = e
		}
		
		xcodeprojURL = URL(fileURLWithPath: xcodeprojPath, isDirectory: true)
		pbxprojURL = xcodeprojURL.appendingPathComponent("project.pbxproj", isDirectory: false)
		
		
		/* *** Load CoreData model *** */
		
		guard let modelURL = Bundle.module.url(forResource: "PBXModel", withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw HagvtoolError(message: "Cannot load CoreData model")
		}
		managedObjectModel = model
		
		persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		try persistentCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		
		managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentCoordinator
		
		pbxproj = try PBXProj(url: pbxprojURL, context: managedObjectContext)
	}
	
}

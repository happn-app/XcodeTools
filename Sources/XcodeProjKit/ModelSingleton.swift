import CoreData
import Foundation



struct ModelSingleton {
	
	let syncQueue = DispatchQueue(label: "com.happn.XcodeTools.ModelSingletonSync")
	
	static var model: NSManagedObjectModel? = {
		return Bundle.module.url(forResource: "PBXModel", withExtension: "momd").flatMap{ NSManagedObjectModel(contentsOf: $0) }
	}()
	
}

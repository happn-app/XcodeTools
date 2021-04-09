import CoreData
import Foundation



struct ModelSingleton {
	
	static var model: NSManagedObjectModel? = {
		return Bundle.module.url(forResource: "PBXModel", withExtension: "momd").flatMap{ NSManagedObjectModel(contentsOf: $0) }
	}()
	
}

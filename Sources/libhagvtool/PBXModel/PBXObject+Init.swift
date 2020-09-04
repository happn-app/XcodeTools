import CoreData
import Foundation



/* Sadly we cannot implement fillValues in an extension because overriding
 * method in extensions is not supported. */
@objc(PBXObject)
public class PBXObject : NSManagedObject {
	
	public static func unsafeInstantiate(rawObjects: [String: [String: Any]], id: String, context: NSManagedObjectContext, decodedObjects: inout [String: PBXObject]) throws -> Self {
		if let decodedObject = decodedObjects[id] {
			guard let result = decodedObject as? Self else {
				throw HagvtoolError(message: "Error, expected an object of type \(self), but got something else in the decoded objects dictionary.")
			}
			return result
		}
		
		let rawObject: [String: Any] = try rawObjects.get(id)
		let isa: String = try rawObject.get("isa")
		
		guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
			throw HagvtoolError(message: "Given context does not have a model!")
		}
		guard let entity = model.entitiesByName[isa] else {
			throw HagvtoolError(message: "Did not find isa \(isa) in the CoreData model.")
		}
		/* Second test here is redundant w/ first one. */
		guard !entity.isAbstract && entity.name != "PBXObject" else {
			throw HagvtoolError(message: "Given isa \(isa) is abstract in the CoreData model!")
		}
		guard entity.topmostSuperentity().name == "PBXObject" else {
			throw HagvtoolError(message: "Given isa \(isa) whose entity is not related to PBXObject! This is an internal logic error.")
		}
		
		/* First let’s see if the object is not already in the graph */
		let fetchRequest = NSFetchRequest<PBXObject>()
		fetchRequest.entity = entity
		fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(PBXObject.id), id)
		let results = try context.fetch(fetchRequest)
		guard results.count <= 1 else {
			throw HagvtoolError(message: "Internal error: got \(results.count) where at most 1 was expected.")
		}
		
		let created: Bool
		let resultObject: PBXObject
		if let r = results.first {resultObject = r;                                              created = false}
		else                     {resultObject = PBXObject(entity: entity, insertInto: context); created = true}
		
		guard let result = resultObject as? Self else {
			if created {context.delete(resultObject)}
			throw HagvtoolError(message: "Error, expected an object of type \(self), but got something else.")
		}
		
		do {
			result.setValue(id, forKey: #keyPath(PBXObject.id)) /* Could be done in fillValues, but would require to give the id to fillValues… */
			try result.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
			decodedObjects[id] = result
			return result
		} catch {
			if created {
				context.delete(resultObject)
			}
			throw error
		}
	}
	
	open func fillValues(rawObject: [String: Any], rawObjects: [String: [String: Any]], context: NSManagedObjectContext, decodedObjects: inout [String: PBXObject]) throws {
		guard context === managedObjectContext else {
			throw HagvtoolError(message: "Internal error: asked to fill values of an object with a context != than object’s context")
		}
		
		self.rawObject = rawObject
	}
	
}

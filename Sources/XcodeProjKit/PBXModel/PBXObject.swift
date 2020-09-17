import CoreData
import Foundation



/* Sadly we cannot implement fillValues in an extension because overriding
 * method in extensions is not supported. */
@objc(PBXObject)
public class PBXObject : NSManagedObject {
	
	/* Set to true to allow allocate unknown objects as PBXObjects. */
	static let allowPBXObjectAllocation = false
	
	open class func propertyRenamings() -> [String: String] {
		return ["xcID": "id"]
	}
	
	public static func unsafeInstantiate(rawObjects: [String: [String: Any]], id: String, context: NSManagedObjectContext, decodedObjects: inout [String: PBXObject]) throws -> Self {
		if let decodedObject = decodedObjects[id] {
			guard let result = decodedObject as? Self else {
				throw XcodeProjKitError(message: "Error, expected an object of type \(self), but got something else in the decoded objects dictionary for id \(id).")
			}
			return result
		}
		
		let rawObject: [String: Any] = try rawObjects.get(id)
		let isa: String = try rawObject.get("isa")
		
		guard let model = context.persistentStoreCoordinator?.managedObjectModel else {
			throw XcodeProjKitError(message: "Given context does not have a model!")
		}
		guard let entity = model.entitiesByName[isa] ?? (allowPBXObjectAllocation ? model.entitiesByName["PBXObject"] : nil) else {
			throw XcodeProjKitError(message: "Did not find isa \(isa) in the CoreData model.")
		}
		guard !entity.isAbstract || (allowPBXObjectAllocation && entity.name == "PBXObject") else {
			throw XcodeProjKitError(message: "Given isa \(isa) is abstract in the CoreData model (entity = \(entity.name ?? "<unknown>")")
		}
		guard entity.topmostSuperentity().name == "PBXObject" else {
			throw XcodeProjKitError(message: "Given isa \(isa) whose entity is not related to PBXObject! This is an internal logic error.")
		}
		
		/* First let’s see if the object is not already in the graph */
		let fetchRequest = NSFetchRequest<PBXObject>()
		fetchRequest.entity = entity
		fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(PBXObject.xcID), id)
		let results = try context.fetch(fetchRequest)
		guard results.count <= 1 else {
			throw XcodeProjKitError(message: "Internal error: got \(results.count) where at most 1 was expected.")
		}
		
		let created: Bool
		let resultObject: PBXObject
		if let r = results.first {resultObject = r;                                              created = false}
		else                     {resultObject = PBXObject(entity: entity, insertInto: context); created = true}
		
		guard let result = resultObject as? Self else {
			if created {context.delete(resultObject)}
			throw XcodeProjKitError(message: "Error, expected an object of type \(self), but got something else for id \(id).")
		}
		
		do {
			result.setValue(id,  forKey: #keyPath(PBXObject.xcID))   /* Could be done in fillValues, but would require to give the id  to fillValues… */
			result.setValue(isa, forKey: #keyPath(PBXObject.rawISA)) /* Could be done in fillValues, but would require to give the isa to fillValues… */
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
			throw XcodeProjKitError(message: "Internal error: asked to fill values of an object with a context != than object’s context")
		}
		
		self.rawObject = rawObject
		
		/* Let’s validate we know all the properties in the raw object. */
		let renamings = Self.propertyRenamings()
		let unknownProperties = Set(rawObject.keys).subtracting(entity.propertiesByName.keys.map{ renamings[$0] ?? $0 }).subtracting(["isa"])
		if !unknownProperties.isEmpty {
			NSLog("%@", "Warning: In object of type \(rawISA ?? "<unknown>"), instantiated w/ class \(entity.name ?? "<unknown>"), with ID \(xcID ?? "<unknown>"), got the following unknown properties: \(unknownProperties.sorted())")
		}
	}
	
	open var oneLineStringSerialization: Bool {
		return false
	}
	
	open var stringSerializationName: String? {
		return nil
	}
	
	public var xcIDAndComment: String? {
		return xcID.flatMap{ $0 + (stringSerializationName.flatMap{ " /* \($0) */" } ?? "") }
	}
	
	public func stringSerialization(indentCount: Int = 0, indentBase: String = "\t") throws -> String {
		let indent = String(repeating: indentBase, count: indentCount)
		
		var ret = ""
		ret += try """
			
			\(indent)\(xcIDAndComment.get())
			"""
		
		ret += " = {"
		
		if !oneLineStringSerialization {
			ret += "\n\(indent)\(indentBase)"
		}
		ret += try "isa = \(rawISA.get().escapedForPBXProjValue());"
		
		if !oneLineStringSerialization {
			ret += "\n\(indent)"
		}
		ret += "};"
		
		return ret
	}
	
}

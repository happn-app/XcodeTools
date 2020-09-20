import CoreData
import Foundation



public struct PBXProj {
	
	public let rawDecoded: [String: Any]
	
	/** Should always be 1 (only version supported). */
	public let archiveVersion: String
	
	public let objectVersion: String
	
	/** The ID of the root object. */
	public let rootObjectID: String
	
	/** The pbxproj file can contain a “classes” property (it usually does),
	which is usually empty (I have never seen a file where it’s not). We keep the
	information whether the property was present to be able to rewrite the
	pbxproj. */
	public let hasClassesProperty: Bool
	
	/**
	All the objects in the project, keyed by their IDs. */
	public let rawObjects: [String: [String: Any]]
	
	public let rootObject: PBXProject
	
	public init(url: URL, context: NSManagedObjectContext) throws {
		let data = try Data(contentsOf: url)
		
		//var format = PropertyListSerialization.PropertyListFormat.xml
		guard let decoded = try PropertyListSerialization.propertyList(from: data, options: [], format: nil/*&format*/) as? [String: Any] else {
			throw XcodeProjKitError(message: "Got unexpected type for decoded pbxproj plist (not [String: Any]) in pbxproj.")
		}
		/* Now, "format" is (should be) PropertyListSerialization.PropertyListFormat.openStep */
		
		rawDecoded = decoded
		
		archiveVersion = try rawDecoded.get("archiveVersion")
		guard archiveVersion == "1" else {
			throw XcodeProjKitError(message: "Got unexpected value for the “archiveVersion” property in pbxproj.")
		}
		
		let ov: String = try rawDecoded.get("objectVersion")
		guard ov == "46" || ov == "48" || ov == "50" || ov == "52" || ov == "53" || ov == "54" else {
			throw XcodeProjKitError(message: "Got unexpected value “\(ov)” for the “objectVersion” property in pbxproj.")
		}
		objectVersion = ov
		
		let classes: [String: Any]? = try rawDecoded.getIfExists("classes")
		guard classes?.isEmpty ?? true else {
			throw XcodeProjKitError(message: "The “classes” property is not empty in pbxproj; bailing out because we don’t know what this means.")
		}
		hasClassesProperty = (classes != nil)
		
		let roid: String = try rawDecoded.get("rootObject")
		let ro: [String: [String: Any]] = try rawDecoded.get("objects")
		rootObjectID = roid
		rawObjects = ro
		
		guard rawDecoded.count == (classes == nil ? 4 : 5) else {
			throw XcodeProjKitError(message: "Got unexpected properties in pbxproj.")
		}
		
		rootObject = try context.performAndWait{
			var decodedObjects = [String: PBXObject]()
			for key in ro.keys {
				_ = try PBXObject.unsafeInstantiate(rawObjects: ro, id: key, context: context, decodedObjects: &decodedObjects)
			}
			let ret = try PBXProject.unsafeInstantiate(rawObjects: ro, id: roid, context: context, decodedObjects: &decodedObjects)
			do {
				try context.save()
			} catch {
//				NSLog("%@", "\(((error as NSError).userInfo["NSDetailedErrors"] as? [NSError])?.first?.userInfo["NSValidationErrorObject"])")
				context.rollback()
				throw error
			}
			return ret
		}
	}
	
	public func stringSerialization(projectName: String) throws -> String {
		guard let context = rootObject.managedObjectContext else {
			throw XcodeProjKitError(message: "Cannot serialize PBXProj because the root object does not have a context")
		}
		
		var ret = """
			// !$*UTF8*$!
			{
				archiveVersion = \(archiveVersion.escapedForPBXProjValue());
			"""
		if hasClassesProperty {
			ret += """
				
					classes = {
					};
				"""
		}
		ret += """
			
				objectVersion = \(objectVersion.escapedForPBXProjValue());
				objects = {
			"""
		
		try context.performAndWait{
			let request: NSFetchRequest<PBXObject> = PBXObject.fetchRequest()
			request.sortDescriptors = [
				NSSortDescriptor(keyPath: \PBXObject.rawISA, ascending: true),
				NSSortDescriptor(keyPath: \PBXObject.xcID, ascending: true)
			]
			
			var previousISA: String?
			func printEndSection() {
				if let previousISA = previousISA {
					ret += """
							
							/* End \(previousISA) section */
							"""
				}
			}
			
			for object in try context.fetch(request) {
				let isa = try object.rawISA.get()
				if isa != previousISA {
					printEndSection()
					ret += """
						
						
						/* Begin \(isa) section */
						"""
				}
				previousISA = isa
				ret += try object.stringSerialization(projectName: projectName, indentCount: 2)
			}
			printEndSection()
		}
		
		let idAndComment = try rootObject.xcIDAndCommentString(projectName: projectName).get()
		ret += """
			
				};
				rootObject = \(idAndComment);
			}
			
			"""
		
		return ret
	}
	
}

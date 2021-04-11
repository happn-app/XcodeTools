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
		let data = try Result{ try Data(contentsOf: url) }.mapError{ XcodeProjError.cannotReadFile(url, $0) }.get()
		
		var format = PropertyListSerialization.PropertyListFormat.xml
		let decodedUntyped = try Result{ try PropertyListSerialization.propertyList(from: data, options: [], format: &format) }
			.mapError{ XcodeProjError.parseError(.pbxprojPlistParseError($0), objectID: nil) }.get()
		
		if format != .openStep {
			XcodeProjConfig.logger?.warning("pbxproj file was deserialized w/ plist format \(format), which is unexpected (expected OpenStep format). Serialization will probably be different than source.")
		}
		
		guard let decoded = decodedUntyped as? [String: Any] else {
			throw XcodeProjError.parseError(.deserializedPBXProjPlistHasInvalidType, objectID: nil)
		}
		
		rawDecoded = decoded
		
		archiveVersion = try rawDecoded.getForParse("archiveVersion", nil)
		guard archiveVersion == "1" else {
			throw XcodeProjError.unsupportedPBXProj(.unknownArchiveVersion(archiveVersion))
		}
		
		objectVersion = try rawDecoded.getForParse("objectVersion", nil)
		guard Set(arrayLiteral: "46", "48", "50", "52", "53", "54").contains(objectVersion) else {
			throw XcodeProjError.unsupportedPBXProj(.unknownObjectVersion(objectVersion))
		}
		
		let classes: [String: Any]? = try rawDecoded.getIfExistsForParse("classes", nil)
		guard classes?.isEmpty ?? true else {
			throw XcodeProjError.unsupportedPBXProj(.classesPropertyIsNotEmpty(classes!))
		}
		hasClassesProperty = (classes != nil)
		
		let roid: String = try rawDecoded.getForParse("rootObject", nil)
		let ro: [String: [String: Any]] = try rawDecoded.getForParse("objects", nil)
		rootObjectID = roid
		rawObjects = ro
		
		let unknownProperties = Set(arrayLiteral: "archiveVersion", "objectVersion", "classes", "rootObject", "objects")
			.subtracting(rawDecoded.keys)
		guard unknownProperties.isEmpty else {
			throw XcodeProjError.unsupportedPBXProj(.unknownRootProperties(unknownProperties))
		}
		
		rootObject = try context.performAndWait{
			var decodedObjects = [String: PBXObject]()
			for key in ro.keys {
				_ = try PBXObject.unsafeInstantiate(id: key, on: context, rawObjects: ro, decodedObjects: &decodedObjects)
			}
			let ret = try PBXProject.unsafeInstantiate(id: roid, on: context, rawObjects: ro, decodedObjects: &decodedObjects)
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
		/* It is a programmer error to try and serialize a PBXProj whose root
		 * object has been deleted (nil managed object context), hence the forced
		 * unwrap. */
		let context = rootObject.managedObjectContext!
		
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
				let isa = try object.getISA()
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
		
		let idAndComment = try rootObject.getIDAndCommentForSerialization("xcID", rootObject.xcID, projectName: projectName).asString()
		ret += """
			
				};
				rootObject = \(idAndComment);
			}
			
			"""
		
		return ret
	}
	
}

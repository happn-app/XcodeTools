import CoreData
import Foundation

import Utils



@objc(PBXContainerItemProxy)
public class PBXContainerItemProxy : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"containerPortalID": "containerPortal"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		containerPortalID = try rawObject.get("containerPortal")
		
		remoteInfo = try rawObject.get("remoteInfo")
		remoteGlobalIDString = try rawObject.get("remoteGlobalIDString")
		
		do {
			let proxyTypeStr: String = try rawObject.get("proxyType")
			guard let value = Int16(proxyTypeStr) else {
				throw XcodeProjError(message: "Unexpected proxy type value \(proxyTypeStr)")
			}
			if value != 1 && value != 2 {
				XcodeProjConfig.logger?.warning("Unknown value for proxyType \(proxyTypeStr) in object \(xcID ?? "<unknown>"); expected 1 or 2.")
			}
			proxyType = value
		}
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return rawISA ?? "PBXContainerItemProxy"
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["remoteInfo"] = try remoteInfo.get()
		mySerialization["remoteGlobalIDString"] = try remoteGlobalIDString.get()
		mySerialization["proxyType"] = String(proxyType)
		
		let fRequest: NSFetchRequest<PBXObject> = PBXObject.fetchRequest()
		fRequest.predicate = try NSPredicate(format: "%K == %@", #keyPath(PBXObject.xcID), containerPortalID.get())
		mySerialization["containerPortal"] = try managedObjectContext?.fetch(fRequest).onlyElement?.xcIDAndComment(projectName: projectName).get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

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
		
		containerPortalID = try rawObject.getForParse("containerPortal", xcID)
		
		remoteInfo = try rawObject.getForParse("remoteInfo", xcID)
		remoteGlobalIDString = try rawObject.getForParse("remoteGlobalIDString", xcID)
		
		proxyType = try rawObject.getInt16ForParse("proxyType", xcID)
		if proxyType != 1 && proxyType != 2 {
			XcodeProjConfig.logger?.warning("Unknown value for proxyType \(proxyType) in object \(xcID ?? "<unknown>"); expected 1 or 2.")
		}
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return rawISA ?? "PBXContainerItemProxy"
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["remoteInfo"] = try remoteInfo.getForSerialization("remoteInfo", xcID)
		mySerialization["remoteGlobalIDString"] = try remoteGlobalIDString.getForSerialization("remoteGlobalIDString", xcID)
		mySerialization["proxyType"] = String(proxyType)
		
		let fRequest: NSFetchRequest<PBXObject> = PBXObject.fetchRequest()
		fRequest.predicate = try NSPredicate(format: "%K == %@", #keyPath(PBXObject.xcID), containerPortalID.getForSerialization("containerPortalID", xcID))
		mySerialization["containerPortal"] = try managedObjectContext?.fetch(fRequest).onlyElement?.getIDAndCommentForSerialization("containerPortalID", xcID, projectName: projectName)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

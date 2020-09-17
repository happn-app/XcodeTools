import CoreData
import Foundation



@objc(PBXContainerItemProxy)
public class PBXContainerItemProxy : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		let mine = [
			"containerPortalID": "containerPortal"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		containerPortalID = try rawObject.get("containerPortal")
		
		remoteInfo = try rawObject.get("remoteInfo")
		remoteGlobalIDString = try rawObject.get("remoteGlobalIDString")
		
		do {
			let proxyTypeStr: String = try rawObject.get("proxyType")
			guard let value = Int16(proxyTypeStr) else {
				throw XcodeProjKitError(message: "Unexpected proxy type value \(proxyTypeStr)")
			}
			if value != 1 && value != 2 {
				NSLog("%@", "Warning: Unknown value for proxyType \(proxyTypeStr) in object \(xcID ?? "<unknown>"); expected 1 or 2.")
			}
			proxyType = value
		}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["containerPortal"] = try containerPortalID.get()
		mySerialization["remoteInfo"] = try remoteInfo.get()
		mySerialization["remoteGlobalIDString"] = try remoteGlobalIDString.get()
		mySerialization["proxyType"] = String(proxyType)
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

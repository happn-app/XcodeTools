import CoreData
import Foundation



@objc(PBXContainerItemProxy)
public class PBXContainerItemProxy : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
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
		
		if let proxyTypeStr: String = try rawObject.getIfExists("proxyType") {
			guard let value = Int16(proxyTypeStr) else {
				throw HagvtoolError(message: "Unexpected proxy type value \(proxyTypeStr)")
			}
			if value != 1 {
				NSLog("%@", "Warning: Unknown value for proxyType \(proxyTypeStr) in object \(id ?? "<unknown>"); expected 1.")
			}
			proxyType = value
		}
	}
	
}

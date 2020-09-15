import CoreData
import Foundation



@objc(PBXProject)
public class PBXProject : PBXObject {
	
	public override class func propertyRenamings() -> [String : String] {
		let mine = [
			"targets_cd": "targets",
			"packageReferences_cd": "packageReferences"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		attributes = try rawObject.getIfExists("attributes")
		
		compatibilityVersion = try rawObject.get("compatibilityVersion")
		
		projectDirPath = try rawObject.get("projectDirPath")
		projectRoot = try rawObject.getIfExists("projectRoot")
		if !(projectRoot?.isEmpty ?? true) {
			NSLog("%@", "Warning: Suspicious non empty value for projectRoot: \(projectRoot ?? "<nil>"). This probably changes nothing, but I can’t guarantee it.")
		}
		
		knownRegions = try rawObject.get("knownRegions")
		developmentRegion = try rawObject.get("developmentRegion")
		
		do {
			let hasScannedForEncodingsStr: String = try rawObject.get("hasScannedForEncodings")
			guard let value = Int(hasScannedForEncodingsStr) else {
				throw XcodeProjKitError(message: "Unexpected has scanned for encodings value \(hasScannedForEncodingsStr)")
			}
			if value != 0 && value != 1 {
				NSLog("%@", "Warning: Suspicious value for hasScannedForEncodings \(hasScannedForEncodingsStr) in object \(xcID ?? "<unknown>"); expecting 0 or 1; setting to true.")
			}
			hasScannedForEncodings = (value != 0)
		}
		
		let targetIDs: [String] = try rawObject.get("targets")
		targets = try targetIDs.map{ try PBXTarget.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let packageReferenceIDs: [String]? = try rawObject.getIfExists("packageReferences")
		packageReferences = try packageReferenceIDs.flatMap{ try $0.map{ try XCRemoteSwiftPackageReference.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) } }
		
		let mainGroupIDs: String = try rawObject.get("mainGroup")
		mainGroup = try PBXGroup.unsafeInstantiate(rawObjects: rawObjects, id: mainGroupIDs, context: context, decodedObjects: &decodedObjects)
		
		let productRefGroupID: String? = try rawObject.getIfExists("productRefGroup")
		productRefGroup = try productRefGroupID.flatMap{ try PBXGroup.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let buildConfigurationListID: String = try rawObject.get("buildConfigurationList")
		buildConfigurationList = try XCConfigurationList.unsafeInstantiate(rawObjects: rawObjects, id: buildConfigurationListID, context: context, decodedObjects: &decodedObjects)
		
		projectReferences = try rawObject.getIfExists("projectReferences")
	}
	
	public var targets: [PBXTarget]? {
		get {targets_cd?.array as! [PBXTarget]?}
		set {targets_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public var packageReferences: [XCRemoteSwiftPackageReference]? {
		get {packageReferences_cd?.array as! [XCRemoteSwiftPackageReference]?}
		set {packageReferences_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
}

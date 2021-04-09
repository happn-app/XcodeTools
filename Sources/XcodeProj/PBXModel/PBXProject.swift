import CoreData
import Foundation



@objc(PBXProject)
public class PBXProject : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		let mine = [
			"targets_cd": "targets",
			"projectReferences_cd": "projectReferences",
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
				throw XcodeProjError(message: "Unexpected has scanned for encodings value \(hasScannedForEncodingsStr)")
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
		
		if let rawProjectReferences: [[String: String]] = try rawObject.getIfExists("projectReferences") {
			projectReferences = try rawProjectReferences.map{ rawProjectReference in
				guard
					let productGroupID = rawProjectReference["ProductGroup"],
					let projectRefID = rawProjectReference["ProjectRef"],
					rawProjectReference.count == 2
				else {
					throw XcodeProjError(message: "Invalid (or unknown) project reference")
				}
				let projectReference = ProjectReference(context: context)
				projectReference.productGroup = try PBXFileElement.unsafeInstantiate(rawObjects: rawObjects, id: productGroupID, context: context, decodedObjects: &decodedObjects)
				projectReference.projectRef = try PBXFileElement.unsafeInstantiate(rawObjects: rawObjects, id: projectRefID, context: context, decodedObjects: &decodedObjects)
				return projectReference
			}
		}
	}
	
	public var targets: [PBXTarget]? {
		get {targets_cd?.array as! [PBXTarget]?}
		set {targets_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public var packageReferences: [XCRemoteSwiftPackageReference]? {
		get {PBXObject.getOptionalToMany(packageReferences_cd, packageReferences_isSet)}
		set {(packageReferences_cd, packageReferences_isSet) = PBXObject.setOptionalToManyTuple(newValue)}
	}
	
	public var projectReferences: [ProjectReference]? {
		get {PBXObject.getOptionalToMany(projectReferences_cd, projectReferences_isSet)}
		set {(projectReferences_cd, projectReferences_isSet) = PBXObject.setOptionalToManyTuple(newValue)}
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return "Project object"
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let a = attributes        {mySerialization["attributes"]        = a}
		if let r = projectRoot       {mySerialization["projectRoot"]       = r}
		if let r = packageReferences {mySerialization["packageReferences"] = try r.map{ try $0.xcIDAndComment(projectName: projectName).get() }}
		if let r = productRefGroup   {mySerialization["productRefGroup"]   = try r.xcIDAndComment(projectName: projectName).get()}
		if let r = projectReferences {
			mySerialization["projectReferences"] = r
		}
		mySerialization["compatibilityVersion"]   = try compatibilityVersion.get()
		mySerialization["projectDirPath"]         = try projectDirPath.get()
		mySerialization["knownRegions"]           = try knownRegions.get()
		mySerialization["developmentRegion"]      = try developmentRegion.get()
		mySerialization["hasScannedForEncodings"] = hasScannedForEncodings ? "1" : "0"
		mySerialization["targets"]                = try targets.get().map{ try $0.xcIDAndComment(projectName: projectName).get() }
		mySerialization["mainGroup"]              = try mainGroup.get().xcIDAndComment(projectName: projectName).get()
		mySerialization["buildConfigurationList"] = try buildConfigurationList.get().xcIDAndComment(projectName: projectName).get()
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

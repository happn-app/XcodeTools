import CoreData
import Foundation



@objc(PBXProject)
public class PBXProject : PBXObject {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"targets_cd": "targets",
			"projectReferences_cd": "projectReferences",
			"packageReferences_cd": "packageReferences"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		attributes = try rawObject.getIfExistsForParse("attributes", xcID)
		
		compatibilityVersion = try rawObject.getForParse("compatibilityVersion", xcID)
		
		projectDirPath = try rawObject.getForParse("projectDirPath", xcID)
		projectRoot = try rawObject.getIfExistsForParse("projectRoot", xcID)
		if !(projectRoot?.isEmpty ?? true) {
			XcodeProjConfig.logger?.warning("Suspicious non empty value for projectRoot: \(projectRoot ?? "<nil>"). This probably changes nothing, but I can’t guarantee it.")
		}
		
		knownRegions = try rawObject.getForParse("knownRegions", xcID)
		developmentRegion = try rawObject.getForParse("developmentRegion", xcID)
		
		hasScannedForEncodings = try rawObject.getBoolForParse("hasScannedForEncodings", xcID)
		
		let targetIDs: [String] = try rawObject.getForParse("targets", xcID)
		targets = try targetIDs.map{ try PBXTarget.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let packageReferenceIDs: [String]? = try rawObject.getIfExistsForParse("packageReferences", xcID)
		packageReferences = try packageReferenceIDs.flatMap{ try $0.map{ try XCRemoteSwiftPackageReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) } }
		
		let mainGroupIDs: String = try rawObject.getForParse("mainGroup", xcID)
		mainGroup = try PBXGroup.unsafeInstantiate(id: mainGroupIDs, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
		
		let productRefGroupID: String? = try rawObject.getIfExistsForParse("productRefGroup", xcID)
		productRefGroup = try productRefGroupID.flatMap{ try PBXGroup.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let buildConfigurationListID: String = try rawObject.getForParse("buildConfigurationList", xcID)
		buildConfigurationList = try XCConfigurationList.unsafeInstantiate(id: buildConfigurationListID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
		
		if let rawProjectReferences: [[String: String]] = try rawObject.getIfExistsForParse("projectReferences", xcID) {
			projectReferences = try rawProjectReferences.map{ rawProjectReference in
				guard
					let productGroupID = rawProjectReference["ProductGroup"],
					let projectRefID = rawProjectReference["ProjectRef"],
					rawProjectReference.count == 2
				else {
					throw XcodeProjError.parseError(.unknownOrInvalidProjectReference(rawProjectReference), objectID: xcID)
				}
				let projectReference = ProjectReference(context: context)
				projectReference.productGroup = try PBXFileElement.unsafeInstantiate(id: productGroupID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
				projectReference.projectRef = try PBXFileElement.unsafeInstantiate(id: projectRefID, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects)
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
		if let r = packageReferences {mySerialization["packageReferences"] = try r.getIDsAndCommentsForSerialization("packageReferences", xcID, projectName: projectName)}
		if let r = productRefGroup   {mySerialization["productRefGroup"]   = try r.getIDAndCommentForSerialization("productRefGroup", xcID, projectName: projectName)}
		if let r = projectReferences {
			mySerialization["projectReferences"] = r
		}
		mySerialization["compatibilityVersion"]   = try compatibilityVersion.getForSerialization("compatibilityVersion", xcID)
		mySerialization["projectDirPath"]         = try projectDirPath.getForSerialization("projectDirPath", xcID)
		mySerialization["knownRegions"]           = try knownRegions.getForSerialization("knownRegions", xcID)
		mySerialization["developmentRegion"]      = try developmentRegion.getForSerialization("developmentRegion", xcID)
		mySerialization["hasScannedForEncodings"] = hasScannedForEncodings ? "1" : "0"
		mySerialization["targets"]                = try targets.getForSerialization("targets", xcID).getIDsAndCommentsForSerialization("targets", xcID, projectName: projectName)
		mySerialization["mainGroup"]              = try mainGroup.getIDAndCommentForSerialization("mainGroup", xcID, projectName: projectName)
		mySerialization["buildConfigurationList"] = try buildConfigurationList.getIDAndCommentForSerialization("buildConfigurationList", xcID, projectName: projectName)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

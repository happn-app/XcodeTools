import CoreData
import Foundation



@objc(PBXNativeTarget)
public class PBXNativeTarget : PBXTarget {
	
	open override class func propertyRenamings() -> [String : String] {
		return super.propertyRenamings().mergingUnambiguous([
			"buildRules_cd": "buildRules",
			"packageProductDependencies_cd": "packageProductDependencies"
		])
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let productReferenceID: String? = try rawObject.getIfExists("productReference")
		productReference = try productReferenceID.flatMap{ try PBXFileReference.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		productType = try rawObject.get("productType")
		productInstallPath = try rawObject.getIfExists("productInstallPath")
		
		let buildRulesIDs: [String]? = try rawObject.getIfExists("buildRules")
		buildRules = try buildRulesIDs?.map{ try PBXBuildRule.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
		
		let packageProductDependenciesIDs: [String]? = try rawObject.getIfExists("packageProductDependencies")
		packageProductDependencies = try packageProductDependenciesIDs?.map{ try XCSwiftPackageProductDependency.unsafeInstantiate(id: $0, on: context, rawObjects: rawObjects, decodedObjects: &decodedObjects) }
	}
	
	public var buildRules: [PBXBuildRule]? {
		get {PBXObject.getOptionalToMany(buildRules_cd, buildRules_isSet)}
		set {(buildRules_cd, buildRules_isSet) = PBXObject.setOptionalToManyTuple(newValue)}
	}
	
	public var packageProductDependencies: [XCSwiftPackageProductDependency]? {
		get {PBXObject.getOptionalToMany(packageProductDependencies_cd, packageProductDependencies_isSet)}
		set {(packageProductDependencies_cd, packageProductDependencies_isSet) = PBXObject.setOptionalToManyTuple(newValue)}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let r = buildRules                 {mySerialization["buildRules"]                 = try r.map{ try $0.xcIDAndComment(projectName: projectName).get() }}
		if let r = productReference           {mySerialization["productReference"]           = try r.xcIDAndComment(projectName: projectName).get()}
		if let p = productInstallPath         {mySerialization["productInstallPath"]         = p}
		if let r = packageProductDependencies {mySerialization["packageProductDependencies"] = try r.map{ try $0.xcIDAndComment(projectName: projectName).get() }}
		mySerialization["productType"] = try productType.get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

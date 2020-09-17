import CoreData
import Foundation



@objc(PBXNativeTarget)
public class PBXNativeTarget : PBXTarget {
	
	open override class func propertyRenamings() -> [String : String] {
		let mine = [
			"buildRules_cd": "buildRules",
			"packageProductDependencies_cd": "packageProductDependencies"
		]
		return super.propertyRenamings().merging(mine, uniquingKeysWith: { current, new in
			precondition(current == new, "Incompatible property renamings")
			NSLog("%@", "Warning: Internal logic shadiness: Property rename has been declared twice for destination \(current), in class \(self)")
			return current
		})
	}
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		let productReferenceID: String? = try rawObject.getIfExists("productReference")
		productReference = try productReferenceID.flatMap{ try PBXFileReference.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		productType = try rawObject.get("productType")
		productInstallPath = try rawObject.getIfExists("productInstallPath")
		
		let buildRulesIDs: [String]? = try rawObject.getIfExists("buildRules")
		buildRules = try buildRulesIDs?.map{ try PBXBuildRule.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
		
		let packageProductDependenciesIDs: [String]? = try rawObject.getIfExists("packageProductDependencies")
		packageProductDependencies = try packageProductDependenciesIDs?.map{ try XCSwiftPackageProductDependency.unsafeInstantiate(rawObjects: rawObjects, id: $0, context: context, decodedObjects: &decodedObjects) }
	}
	
	public var buildRules: [PBXBuildRule]? {
		get {buildRules_cd?.array as! [PBXBuildRule]?}
		set {buildRules_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	public var packageProductDependencies: [XCSwiftPackageProductDependency]? {
		get {packageProductDependencies_cd?.array as! [XCSwiftPackageProductDependency]?}
		set {packageProductDependencies_cd = newValue.flatMap{ NSOrderedSet(array: $0) }}
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		if let r = buildRules                 {mySerialization["buildRules"]                 = try r.map{ try $0.xcIDAndComment(projectName: projectName).get() }}
		if let r = productReference           {mySerialization["productReference"]           = try r.xcIDAndComment(projectName: projectName).get()}
		if let p = productInstallPath         {mySerialization["productInstallPath"]         = p}
		if let r = packageProductDependencies {mySerialization["packageProductDependencies"] = try r.map{ try $0.xcIDAndComment(projectName: projectName).get() }}
		mySerialization["productType"] = try productType.get()
		
		let parentSerialization = try super.knownValuesSerialized(projectName: projectName)
		return parentSerialization.merging(mySerialization, uniquingKeysWith: { current, new in
			NSLog("%@", "Warning: My serialization overrode parent’s serialization’s value “\(current)” with “\(new)” for object of type \(rawISA ?? "<unknown>") with id \(xcID ?? "<unknown>").")
			return new
		})
	}
	
}

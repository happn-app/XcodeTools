import CoreData
import Foundation



@objc(XCRemoteSwiftPackageReference)
public class XCRemoteSwiftPackageReference : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		repositoryURL = try rawObject.getURLForParse("repositoryURL", xcID)
		requirement = try rawObject.getForParse("requirement", xcID)
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return "XCRemoteSwiftPackageReference" + (repositoryURL.flatMap{ " \"" + $0.deletingPathExtension().lastPathComponent + "\"" } ?? "")
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["repositoryURL"] = try getRepositoryURL().absoluteString
		mySerialization["requirement"] = try getRequirement()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
	public func getRepositoryURL() throws -> URL           {try PBXObject.getNonOptionalValue(repositoryURL, "repositoryURL", xcID)}
	public func getRequirement()   throws -> [String: Any] {try PBXObject.getNonOptionalValue(requirement,   "requirement",   xcID)}
	
	/**
	 Will find the XCSwiftPackageProductDependency that uses this package reference and return the product name of the product dependency.
	 If the product dependency is not found, returns the last path component of the repository URL without the path extension. */
	public func retrievePackageName() throws -> String {
		let fetchRequest: NSFetchRequest<XCSwiftPackageProductDependency> = XCSwiftPackageProductDependency.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "%K == %@", "package", self)
		return try managedObjectContext?.fetch(fetchRequest).first?.getProductName() ?? getRepositoryURL().deletingPathExtension().lastPathComponent
	}
	
}

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
	 Returns the last path component of the repository URL without the extension.
	 
	 We used to find the XCSwiftPackageProductDependency that uses this package reference and return the product name of the product dependency.
	 However this is incorrect as a swift package module can have more than one product and more than one dep can be added to a target.
	 
	 The proper way to do this would be to _fetch_ the repo and parse the Package.swift file, but that’s too slow.
	 
	 So we return something that is ok most of the time. */
	public func getPackageName() throws -> String {
		return try getRepositoryURL().deletingPathExtension().lastPathComponent
	}
	
}

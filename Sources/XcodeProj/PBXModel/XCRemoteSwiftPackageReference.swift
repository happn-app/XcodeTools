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
		mySerialization["repositoryURL"] = try repositoryURL.getForSerialization("repositoryURL", xcID).absoluteString
		mySerialization["requirement"] = try requirement.getForSerialization("requirement", xcID)
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

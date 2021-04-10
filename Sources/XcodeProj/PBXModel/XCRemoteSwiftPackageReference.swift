import CoreData
import Foundation



@objc(XCRemoteSwiftPackageReference)
public class XCRemoteSwiftPackageReference : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		do {
			let repositoryURLStr: String = try rawObject.get("repositoryURL")
			guard let url = URL(string: repositoryURLStr) else {
				throw XcodeProjError(message: "Expected repositoryURL to be a valid URL in object w/ id \(xcID ?? "<unknown>") but got \(repositoryURLStr)")
			}
			repositoryURL = url
		}
		requirement = try rawObject.get("requirement")
	}
	
	public override func stringSerializationName(projectName: String) -> String? {
		return "XCRemoteSwiftPackageReference" + (repositoryURL.flatMap{ " \"" + $0.deletingPathExtension().lastPathComponent + "\"" } ?? "")
	}
	
	open override func knownValuesSerialized(projectName: String) throws -> [String: Any] {
		var mySerialization = [String: Any]()
		mySerialization["repositoryURL"] = try repositoryURL.get().absoluteString
		mySerialization["requirement"] = try requirement.get()
		
		return try mergeSerialization(super.knownValuesSerialized(projectName: projectName), mySerialization)
	}
	
}

import CoreData
import Foundation



@objc(XCRemoteSwiftPackageReference)
public class XCRemoteSwiftPackageReference : PBXObject {
	
	open override func fillValues(rawObject: [String : Any], rawObjects: [String : [String : Any]], context: NSManagedObjectContext, decodedObjects: inout [String : PBXObject]) throws {
		try super.fillValues(rawObject: rawObject, rawObjects: rawObjects, context: context, decodedObjects: &decodedObjects)
		
		do {
			let repositoryURLStr: String = try rawObject.get("repositoryURL")
			guard let url = URL(string: repositoryURLStr) else {
				throw HagvtoolError(message: "Expected repositoryURL to be a valid URL in object w/ id \(id ?? "<unknown>") but got \(repositoryURLStr)")
			}
			repositoryURL = url
		}
		requirement = try rawObject.get("requirement")
	}
	
}

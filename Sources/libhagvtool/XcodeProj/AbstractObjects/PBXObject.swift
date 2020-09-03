import Foundation



public protocol PBXObject {
	
	static var isa: String {get}
	
	var rawObject: [String: Any] {get}
	
	init(rawObjects: [String: [String: Any]], id: String, factory: PBXObjectFactory) throws
	
}


/* I did not find a better way than this, sadly (targets need not be in this dic). */
let pbxObjectClasses: [String: PBXObject.Type] = [
	PBXProject.isa: PBXProject.self,
	XCConfigurationList.isa: XCConfigurationList.self
]

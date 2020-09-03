import Foundation



public class PBXObjectFactory {
	
	let objectTypeNames: [String: PBXObject.Type]
	let targetTypeNames: [String: PBXTarget.Type]
	
	init(objectNames: [String: PBXObject.Type], targetNames: [String: PBXTarget.Type]) {
		objectTypeNames = objectNames.merging(targetNames, uniquingKeysWith: { current, new in precondition(current == new); return current })
		targetTypeNames = targetNames
	}
	
	func instantiateObject(rawObjects: [String: [String: Any]], id: String) throws -> PBXObject {
		guard let rawObject = rawObjects[id] else {
			throw HagvtoolError(message: "Cannot find object w/ id \(id)")
		}
		let isa: String = try rawObject.get("isa")
		guard let type = objectTypeNames[isa] else {
			throw HagvtoolError(message: "Cannot find object of type \(isa)")
		}
		return try type.init(rawObjects: rawObjects, id: id, factory: self)
	}
	
	func instantiateTarget(rawObjects: [String: [String: Any]], id: String) throws -> PBXTarget {
		guard let rawObject = rawObjects[id] else {
			throw HagvtoolError(message: "Cannot find object w/ id \(id)")
		}
		let isa: String = try rawObject.get("isa")
		guard let type = targetTypeNames[isa] else {
			throw HagvtoolError(message: "Cannot find object of type \(isa)")
		}
		return try type.init(rawObjects: rawObjects, id: id, factory: self)
	}
	
}

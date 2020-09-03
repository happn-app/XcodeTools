import Foundation



public protocol PBXTarget : PBXObject {
	
	var name: String {get}
	
}


let pbxTargetClasses: [String: PBXTarget.Type] = [
	PBXNativeTarget.isa: PBXNativeTarget.self,
	PBXAggregateTarget.isa: PBXAggregateTarget.self
]
